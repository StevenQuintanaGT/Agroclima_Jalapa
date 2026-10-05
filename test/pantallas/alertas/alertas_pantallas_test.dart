import 'dart:async';

import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/alerta.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/parcela.dart';
import 'package:agroclima_jalapa/pantallas/alertas/centro_alertas_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/alertas/centro_alertas_vm.dart';
import 'package:agroclima_jalapa/pantallas/alertas/detalle_alerta_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/alertas/detalle_alerta_vm.dart';
import 'package:agroclima_jalapa/servicios/alertas_servicio.dart';
import 'package:agroclima_jalapa/servicios/compartir_servicio.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../apoyo/alertas_de_prueba.dart';

class _AlertasFalsas extends Mock implements AlertasServicio {}

class _ParcelasFalsas extends Mock implements ParcelasServicio {}

class _CompartirFalso extends Mock implements CompartirServicio {}

void main() {
  setUpAll(() async {
    registerFallbackValue(alertaDePrueba());
    await initializeDateFormatting('es');
  });

  void pantallaDeTelefono(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
  }

  group('centro de alertas (21 y 35)', () {
    Future<void> abrir(WidgetTester tester, List<Alerta> alertas) async {
      pantallaDeTelefono(tester);
      final servicio = _AlertasFalsas();
      when(servicio.misAlertas).thenAnswer((_) => Stream.value(alertas));
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaApp.claro,
          home: ChangeNotifierProvider(
            create: (_) =>
                CentroAlertasVm(servicio, reloj: () => ahoraDePrueba),
            child: const CentroAlertasPantalla(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('sin alertas activas: "Todo tranquilo"', (tester) async {
      await abrir(tester, [alertaDePrueba(dia: 2)]);
      expect(find.text(Textos.todoTranquilo), findsOneWidget);
      await tester.tap(find.text(Textos.anteriores));
      await tester.pumpAndSettle();
      expect(find.text('Puede caer helada'), findsOneWidget);
    });

    testWidgets('PELIGRO primero, con distintivo de las no vistas', (
      tester,
    ) async {
      await abrir(tester, [
        alertaDePrueba(
          id: 'viento',
          tipo: TipoRiesgo.vientoFuerte,
          nivel: NivelSeveridad.preventiva,
          esperado: 20,
          umbral: 15,
          dia: 5,
          cultivo: Cultivo.maiz,
        ),
        alertaDePrueba(id: 'helada', leida: true),
      ]);
      expect(find.text(Textos.todoTranquilo), findsNothing);
      final helada = tester.getTopLeft(find.text('Puede caer helada'));
      final viento = tester.getTopLeft(find.text('Viento fuerte'));
      expect(helada.dy, lessThan(viento.dy));
      expect(find.text('La Joya · Maíz'), findsOneWidget);
      expect(find.text('Mañana en la madrugada'), findsOneWidget);
      expect(find.text('Hoy'), findsOneWidget);
      // Solo el viento está sin abrir.
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('detalle de alerta (22)', () {
    late _AlertasFalsas alertas;
    late _CompartirFalso compartir;
    late StreamController<Alerta?> flujo;

    Future<void> abrir(WidgetTester tester, {Alerta? alerta}) async {
      pantallaDeTelefono(tester);
      alertas = _AlertasFalsas();
      compartir = _CompartirFalso();
      flujo = StreamController<Alerta?>();
      addTearDown(flujo.close);
      final parcelas = _ParcelasFalsas();
      when(() => alertas.observar('a1')).thenAnswer((_) => flujo.stream);
      when(() => alertas.marcarLeida(any())).thenAnswer((_) async {});
      when(() => alertas.marcarAtendida(any())).thenAnswer((_) async {});
      when(() => compartir.compartirTexto(any())).thenAnswer((_) async {});
      when(() => parcelas.observar('joya')).thenAnswer(
        (_) => Stream.value(
          const Parcela(
            parcelaId: 'joya',
            usuarioId: 'ana',
            nombre: 'La Joya',
            municipio: Municipio.mataquescuintla,
            latitud: 14.53,
            longitud: -90.18,
            celdaClima: '14.55_-90.20',
            cultivo: Cultivo.cafe,
            etapa: Etapa.floracion,
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaApp.claro,
          home: ChangeNotifierProvider(
            create: (_) => DetalleAlertaVm(
              alertas: alertas,
              parcelas: parcelas,
              compartir: compartir,
              alertaId: 'a1',
              reloj: () => ahoraDePrueba,
            ),
            child: const DetalleAlertaPantalla(),
          ),
        ),
      );
      flujo.add(alerta);
      await tester.pumpAndSettle();
    }

    testWidgets('esperado frente a lo que aguanta, qué hacer y queda leída', (
      tester,
    ) async {
      await abrir(
        tester,
        alerta: alertaDePrueba(
          nivel: NivelSeveridad.preventiva,
          esperado: 13,
          umbral: 15,
        ),
      );
      expect(find.text('Frío'), findsOneWidget);
      expect(find.text('PRECAUCIÓN'), findsOneWidget);
      expect(find.text('La Joya · Café floreando'), findsOneWidget);
      expect(find.text('Mañana en la madrugada'), findsOneWidget);
      expect(find.text('13 °C'), findsOneWidget);
      expect(find.text('El café aguanta hasta'), findsOneWidget);
      expect(find.text('15 °C'), findsOneWidget);
      expect(
        find.text('Va a estar 2 grados más frío de lo que aguanta su cultivo.'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Proteja el almácigo durante la noche.'),
        200,
      );
      expect(
        find.text('Proteja el almácigo durante la noche.'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(find.text(Textos.avisoApoyo), 200);
      expect(find.text(Textos.avisoApoyo), findsOneWidget);
      verify(() => alertas.marcarLeida(any())).called(1);
    });

    testWidgets('"Ya tomé medidas" y compartir', (tester) async {
      await abrir(tester, alerta: alertaDePrueba());
      await tester.tap(find.text(Textos.yaTomeMedidas));
      await tester.pumpAndSettle();
      expect(find.text(Textos.yaTomoMedidas), findsOneWidget);
      verify(() => alertas.marcarAtendida(any())).called(1);

      await tester.tap(find.text(Textos.avisarWhatsApp));
      await tester.pumpAndSettle();
      final texto =
          verify(() => compartir.compartirTexto(captureAny())).captured.single
              as String;
      expect(texto, contains('PELIGRO: puede caer helada en La Joya'));
    });

    testWidgets('si ya no existe, lo dice y ofrece ver los avisos', (
      tester,
    ) async {
      await abrir(tester);
      expect(find.text(Textos.alertaNoEsta), findsOneWidget);
      expect(find.text(Textos.verAvisos), findsOneWidget);
    });
  });
}
