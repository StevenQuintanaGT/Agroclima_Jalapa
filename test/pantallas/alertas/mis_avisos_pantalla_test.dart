import 'dart:async';

import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/preferencia_alerta.dart';
import 'package:agroclima_jalapa/modelos/umbral.dart';
import 'package:agroclima_jalapa/pantallas/alertas/mis_avisos_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/alertas/mis_avisos_vm.dart';
import 'package:agroclima_jalapa/servicios/avisos_servicio.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _AvisosFalsos extends Mock implements AvisosServicio {}

class _ParcelasFalsas extends Mock implements ParcelasServicio {}

void main() {
  late _AvisosFalsos avisos;

  setUpAll(() => registerFallbackValue(<PreferenciaAlerta>[]));

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    avisos = _AvisosFalsos();
    final parcelas = _ParcelasFalsas();
    when(avisos.misPreferencias)
        .thenAnswer((_) => Stream.value(AvisosServicio.completar(const [])));
    when(() => avisos.guardar(any())).thenAnswer((_) async {});
    when(() => avisos.loQueAguanta(any())).thenAnswer(
      (_) async => {
        Cultivo.cafe: [
          const Umbral(
            umbralId: 'tmin_cafe_preventiva',
            tipoRiesgo: TipoRiesgo.temperaturaBaja,
            variable: 'temperaturaMinima',
            operador: 'menor',
            valor: 15,
            nivel: NivelSeveridad.preventiva,
            cultivo: Cultivo.cafe,
          ),
        ],
      },
    );
    when(parcelas.misParcelas).thenAnswer((_) => Stream.value(const []));
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaApp.claro,
        home: ChangeNotifierProvider(
          create: (_) => MisAvisosVm(avisos: avisos, parcelas: parcelas),
          child: const MisAvisosPantalla(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<PreferenciaAlerta> guardado() =>
      verify(() => avisos.guardar(captureAny())).captured.last
          as List<PreferenciaAlerta>;

  testWidgets('los 6 tipos encendidos, desde Precaución y callado de noche', (
    tester,
  ) async {
    await abrir(tester);
    for (final tipo in TipoRiesgo.values) {
      expect(find.text(Textos.tipoAviso(tipo)), findsOneWidget);
    }
    expect(
      tester.widgetList<Switch>(find.byType(Switch)).every((s) => s.value),
      isTrue,
    );
    expect(find.text(Textos.aunqueApague), findsOneWidget);
    await tester.scrollUntilVisible(find.text(Textos.peligroSiSuena), 200);
    expect(find.text('De 10:00 p.m. a 5:00 a.m.'), findsOneWidget);
  });

  testWidgets('apagar un tipo lo guarda al instante', (tester) async {
    await abrir(tester);
    await tester.tap(find.text(Textos.tipoAviso(TipoRiesgo.vientoFuerte)));
    await tester.pumpAndSettle();
    final lista = guardado();
    expect(
      lista.firstWhere((p) => p.tipoRiesgo == TipoRiesgo.vientoFuerte).activa,
      isFalse,
    );
    expect(lista.where((p) => p.activa), hasLength(5));
  });

  testWidgets('"Solo peligro" y quitar el silencio', (tester) async {
    await abrir(tester);
    await tester.ensureVisible(find.text('Solo peligro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solo peligro'));
    await tester.pumpAndSettle();
    expect(
      guardado().every((p) => p.nivelMinimo == NivelSeveridad.critica),
      isTrue,
    );

    await tester.ensureVisible(find.text(Textos.peligroSiSuena));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Textos.peligroSiSuena));
    await tester.pumpAndSettle();
    expect(guardado().every((p) => !p.silencioActivo), isTrue);
  });

  testWidgets('muestra lo que aguanta el cultivo, sin poder cambiarlo', (
    tester,
  ) async {
    await abrir(tester);
    await tester.scrollUntilVisible(find.text('15 °C'), 200);
    expect(find.text(Textos.loQueAguanta), findsOneWidget);
    expect(find.text('Café'), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
  });
}
