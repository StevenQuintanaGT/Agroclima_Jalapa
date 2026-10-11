import 'package:agroclima_jalapa/config/constantes.dart';
import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/alerta.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/pantallas/alertas/centro_alertas_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/alertas/centro_alertas_vm.dart';
import 'package:agroclima_jalapa/servicios/alertas_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../apoyo/alertas_de_prueba.dart';

class _AlertasFalsas extends Mock implements AlertasServicio {}

/// Alertas de días pasados en dos parcelas.
final _anteriores = [
  alertaDePrueba(
    id: 'h1',
    parcelaId: 'joya',
    dia: 3,
    atendida: true,
    leida: true,
  ),
  alertaDePrueba(
    id: 'h2',
    parcelaId: 'guayabal',
    dia: 2,
    tipo: TipoRiesgo.vientoFuerte,
    nivel: NivelSeveridad.preventiva,
    esperado: 20,
    umbral: 15,
    leida: true,
  ),
];

Alerta _conNombre(Alerta a, String nombre) => Alerta(
  alertaId: a.alertaId,
  usuarioId: a.usuarioId,
  parcelaId: a.parcelaId,
  tipoRiesgo: a.tipoRiesgo,
  nivel: a.nivel,
  valorEsperado: a.valorEsperado,
  valorUmbral: a.valorUmbral,
  mensaje: a.mensaje,
  fechaEvento: a.fechaEvento,
  leida: a.leida,
  atendida: a.atendida,
  parcelaNombre: nombre,
  cultivo: a.cultivo,
);

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  final lista = [_anteriores[0], _conNombre(_anteriores[1], 'El Guayabal')];

  group('CentroAlertasVm · historial (HU-14)', () {
    test('filtra por parcela y lista las parcelas por nombre', () async {
      final servicio = _AlertasFalsas();
      when(servicio.misAlertas).thenAnswer((_) => Stream.value(lista));
      final vm = CentroAlertasVm(servicio, reloj: () => ahoraDePrueba);
      await Future<void>.delayed(Duration.zero);
      expect(vm.parcelasAnteriores, [
        ('guayabal', 'El Guayabal'),
        ('joya', 'La Joya'),
      ]);
      expect(vm.anteriores, hasLength(2));
      vm.filtrarParcela('joya');
      expect(vm.anteriores.map((a) => a.alertaId), ['h1']);
      vm.filtrarParcela(null);
      expect(vm.anteriores, hasLength(2));
    });

    test(
      '"Ver más" pide otras tantas solo si llegaron todas las pedidas',
      () async {
        final servicio = _AlertasFalsas();
        final llenas = List.generate(
          Constantes.alertasEnLista,
          (i) => alertaDePrueba(id: 'a$i', dia: 1),
        );
        when(servicio.misAlertas).thenAnswer((_) => Stream.value(llenas));
        when(() => servicio.misAlertas(limite: any(named: 'limite')))
            .thenAnswer((_) => Stream.value(llenas.take(150).toList()));
        final vm = CentroAlertasVm(servicio, reloj: () => ahoraDePrueba);
        await Future<void>.delayed(Duration.zero);
        expect(vm.hayMas, isTrue);
        vm.verMas();
        await Future<void>.delayed(Duration.zero);
        verify(() => servicio.misAlertas(limite: Constantes.alertasEnLista * 2))
            .called(1);
        // Llegaron menos de las pedidas: ya no hay más.
        expect(vm.hayMas, isFalse);
      },
    );
  });

  testWidgets('Anteriores: filtro por parcela y "Ya tomó medidas"', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final servicio = _AlertasFalsas();
    when(servicio.misAlertas).thenAnswer((_) => Stream.value(lista));
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaApp.claro,
        home: ChangeNotifierProvider(
          create: (_) => CentroAlertasVm(servicio, reloj: () => ahoraDePrueba),
          child: const CentroAlertasPantalla(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(Textos.anteriores));
    await tester.pumpAndSettle();

    expect(find.text(Textos.todas), findsOneWidget);
    expect(find.text('Puede caer helada'), findsOneWidget);
    expect(find.text('Viento fuerte'), findsOneWidget);
    expect(find.text(Textos.yaTomoMedidas), findsOneWidget);
    expect(find.text(Textos.verMasAvisos), findsNothing);

    await tester.tap(find.text('El Guayabal'));
    await tester.pumpAndSettle();
    expect(find.text('Puede caer helada'), findsNothing);
    expect(find.text('Viento fuerte'), findsOneWidget);
  });
}
