import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/parcela.dart';
import 'package:agroclima_jalapa/modelos/registro_dia.dart';
import 'package:agroclima_jalapa/pantallas/reportes/historial_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/reportes/historial_vm.dart';
import 'package:agroclima_jalapa/repositorios/firestore_historial_repositorio.dart';
import 'package:agroclima_jalapa/servicios/alertas_servicio.dart';
import 'package:agroclima_jalapa/servicios/historial_servicio.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../apoyo/alertas_de_prueba.dart';

class _HistorialFalso extends Mock implements HistorialServicio {}

class _AlertasFalsas extends Mock implements AlertasServicio {}

class _ParcelasFalsas extends Mock implements ParcelasServicio {}

/// Lunes 5 (hoy), domingo 4 con lluvia fuerte y aviso, sábado 3 seco y
/// viernes 2 sin el dato de lluvia del ciclo.
const _registros = [
  RegistroDia(
    fecha: '20261005',
    temperatura: 21,
    temperaturaMinima: 15,
    temperaturaMaxima: 24,
    precipitacion: 0.4,
  ),
  RegistroDia(
    fecha: '20261004',
    temperatura: 19,
    temperaturaMinima: 15,
    temperaturaMaxima: 25,
    precipitacion: 32.4,
  ),
  RegistroDia(
    fecha: '20261003',
    temperatura: 22,
    temperaturaMinima: 14,
    temperaturaMaxima: 28,
    precipitacion: 0,
  ),
  RegistroDia(fecha: '20261002', temperatura: 20),
];

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  final avisosDel4 = [
    alertaDePrueba(
      id: 'a',
      parcelaId: 'joya',
      dia: 4,
      tipo: TipoRiesgo.lluviaIntensa,
      nivel: NivelSeveridad.preventiva,
    ),
    // El mismo riesgo empeoró ese día: cuenta como uno, con el nivel mayor.
    alertaDePrueba(
      id: 'b',
      parcelaId: 'joya',
      dia: 4,
      tipo: TipoRiesgo.lluviaIntensa,
      nivel: NivelSeveridad.critica,
    ),
  ];

  group('HistorialServicio', () {
    test('junta cada día con sus avisos (un aviso por riesgo)', () {
      final dias = HistorialServicio.conAvisos(_registros, avisosDel4);
      expect(dias[1].avisos, 1);
      expect(dias[1].nivelAviso, NivelSeveridad.critica);
      expect(dias[0].avisos, 0);
      expect(dias[0].nivelAviso, isNull);
    });

    test('filtros: con lluvia (≥ 1 mm) y con aviso', () {
      final dias = HistorialServicio.conAvisos(_registros, avisosDel4);
      expect(
        HistorialServicio.filtrar(dias, FiltroHistorial.todo),
        hasLength(4),
      );
      expect(
        HistorialServicio.filtrar(
          dias,
          FiltroHistorial.conLluvia,
        ).map((d) => d.registro.fecha),
        ['20261004'],
      );
      expect(
        HistorialServicio.filtrar(
          dias,
          FiltroHistorial.conAviso,
        ).map((d) => d.registro.fecha),
        ['20261004'],
      );
    });
  });

  test('repositorio: del más nuevo al más viejo, hasta el límite', () async {
    final db = FakeFirebaseFirestore();
    for (final fecha in ['20261001', '20261003', '20261002']) {
      await db.doc('parcelas/joya/condiciones/$fecha').set({
        'fecha': fecha,
        'temperatura': 20,
        'precipitacion': 1.5,
      });
    }
    final dias = await FirestoreHistorialRepositorio(db: db)
        .dias('joya', limite: 2)
        .first;
    expect(dias.map((d) => d.fecha), ['20261003', '20261002']);
    expect(dias.first.precipitacion, 1.5);
    expect(dias.first.temperaturaMaxima, isNull);
  });

  test('textos del día', () {
    expect(Textos.resumenLluviaDia(null), 'Sin dato de lluvia');
    expect(Textos.resumenLluviaDia(0.4), 'Sin lluvia');
    expect(Textos.resumenLluviaDia(8), 'Lluvia ligera');
    expect(Textos.resumenLluviaDia(20), 'Llovió bastante');
    expect(Textos.resumenLluviaDia(32.4), 'Llovió fuerte');
    expect(Textos.detalleDia(8.2, 0), '8 mm de lluvia');
    expect(Textos.detalleDia(32.4, 1), '32 mm · 1 aviso');
    expect(Textos.detalleDia(null, 2), 'Sin dato · 2 avisos');
  });

  group('pantalla (26)', () {
    Future<_HistorialFalso> abrir(
      WidgetTester tester, {
      List<RegistroDia> registros = _registros,
    }) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      final historial = _HistorialFalso();
      final alertas = _AlertasFalsas();
      final parcelas = _ParcelasFalsas();
      when(() => historial.dias('joya', limite: any(named: 'limite')))
          .thenAnswer((_) => Stream.value(registros));
      when(alertas.misAlertas).thenAnswer((_) => Stream.value(avisosDel4));
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
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaApp.claro,
          home: ChangeNotifierProvider(
            create: (_) => HistorialVm(
              historial: historial,
              alertas: alertas,
              parcelas: parcelas,
              parcelaId: 'joya',
              reloj: () => ahoraDePrueba,
            ),
            child: const HistorialPantalla(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return historial;
    }

    testWidgets('un día por fila con lluvia, avisos y máxima/mínima', (
      tester,
    ) async {
      await abrir(tester);
      expect(find.text(Textos.diaPorDia), findsOneWidget);
      expect(find.text('La Joya'), findsOneWidget);
      expect(find.text(Textos.hoy), findsOneWidget);
      expect(find.text('Llovió fuerte'), findsOneWidget);
      expect(find.text('32 mm · 1 aviso'), findsOneWidget);
      expect(find.text('0 mm de lluvia'), findsNWidgets(2));
      expect(find.text('28°'), findsOneWidget);
      expect(find.text('14°'), findsOneWidget);
      // Sin mínima/máxima: la temperatura registrada.
      expect(find.text('Sin dato de lluvia'), findsOneWidget);
      expect(find.text('20°'), findsOneWidget);
    });

    testWidgets('filtro "Con aviso" deja solo el domingo', (tester) async {
      await abrir(tester);
      await tester.ensureVisible(find.text(Textos.filtroConAviso));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Textos.filtroConAviso));
      await tester.pumpAndSettle();
      expect(find.text('Llovió fuerte'), findsOneWidget);
      expect(find.text('Sin lluvia'), findsNothing);
    });

    testWidgets('sin días guardados lo dice', (tester) async {
      await abrir(tester, registros: const []);
      expect(find.text(Textos.sinDias), findsOneWidget);
    });

    testWidgets('"Ver días anteriores" pide otros 30', (tester) async {
      final muchos = [
        for (var i = 0; i < HistorialServicio.diasPorPagina; i++)
          RegistroDia(
            fecha: '202609${(30 - i).toString().padLeft(2, '0')}',
            precipitacion: 0,
          ),
      ];
      final historial = await abrir(tester, registros: muchos);
      await tester.scrollUntilVisible(
        find.text(Textos.verDiasAnteriores),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(Textos.verDiasAnteriores));
      await tester.pumpAndSettle();
      verify(
        () =>
            historial.dias('joya', limite: HistorialServicio.diasPorPagina * 2),
      ).called(1);
    });
  });
}
