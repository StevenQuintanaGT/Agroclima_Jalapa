import 'dart:async';

import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/clima_actual.dart';
import 'package:agroclima_jalapa/modelos/condicion.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/error_clima.dart';
import 'package:agroclima_jalapa/modelos/franja_pronostico.dart';
import 'package:agroclima_jalapa/modelos/parcela.dart';
import 'package:agroclima_jalapa/modelos/pronostico_dia.dart';
import 'package:agroclima_jalapa/modelos/resultado.dart';
import 'package:agroclima_jalapa/pantallas/clima/panel_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/clima/panel_vm.dart';
import 'package:agroclima_jalapa/servicios/clima_servicio.dart';
import 'package:agroclima_jalapa/servicios/conectividad_servicio.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../apoyo/preferencias_falsas.dart';

class _ParcelasFalsas extends Mock implements ParcelasServicio {}

class _ClimaFalso extends Mock implements ClimaServicio {}

class _RedFalsa extends Mock implements ConectividadServicio {}

/// 3 de octubre, 12:00 en Guatemala.
final _ahora = DateTime.utc(2026, 10, 3, 18);

const _guayabal = Parcela(
  parcelaId: 'p1',
  usuarioId: 'u1',
  nombre: 'El Guayabal',
  municipio: Municipio.jalapa,
  latitud: 14.6339,
  longitud: -89.9889,
  altitud: 1380,
  celdaClima: '14.65_-90.00',
);

const _joya = Parcela(
  parcelaId: 'p2',
  usuarioId: 'u1',
  nombre: 'La Joya',
  municipio: Municipio.mataquescuintla,
  latitud: 14.53,
  longitud: -90.18,
  celdaClima: '14.55_-90.20',
);

final _soleado = ClimaActual(
  fechaHora: _ahora,
  temperatura: 24.4,
  sensacionTermica: 26,
  humedadRelativa: 68,
  lluviaUltimaHora: 0,
  velocidadViento: 18,
  direccionViento: 45,
  codigoClima: 800,
  salidaSol: DateTime.utc(2026, 10, 3, 11, 52),
  puestaSol: DateTime.utc(2026, 10, 3, 23, 48),
);

final _franjas = [
  for (var i = 0; i < 4; i++)
    FranjaPronostico(
      fechaHora: _ahora.add(Duration(hours: 3 * i)),
      temperatura: 22,
      temperaturaMinima: 20,
      temperaturaMaxima: 24,
      humedadRelativa: 70,
      lluvia3h: 0,
      velocidadViento: 10,
      probabilidadLluvia: i * 0.1,
      codigoClima: 801,
    ),
];

void main() {
  setUpAll(() async {
    registerFallbackValue(_guayabal);
    await initializeDateFormatting('es');
  });

  late _ParcelasFalsas parcelas;
  late _ClimaFalso clima;
  late PreferenciasFalsas preferencias;
  late StreamController<List<Parcela>> lista;

  setUp(() {
    parcelas = _ParcelasFalsas();
    clima = _ClimaFalso();
    preferencias = PreferenciasFalsas();
    lista = StreamController<List<Parcela>>.broadcast();
    when(parcelas.misParcelas).thenAnswer((_) => lista.stream);
    when(() => clima.condicionDeHoy(any())).thenAnswer(
      (_) => Stream.value(
        Condicion(
          fecha: '20261003',
          fechaHora: _ahora,
          temperatura: 24,
          humedadRelativa: 68,
          velocidadViento: 18,
          precipitacion: 0,
        ),
      ),
    );
    when(() => clima.proximosDias(any())).thenAnswer(
      (_) => Stream.value(const [
        PronosticoDia(
          fecha: '20261003',
          temperaturaMinima: 14,
          temperaturaMaxima: 28,
          precipitacionHora: 0,
          acumuladoDia: 0,
          velocidadViento: 20,
          humedadRelativa: 70,
        ),
      ]),
    );
    when(() => clima.porHoras(any(), forzar: any(named: 'forzar'))).thenAnswer(
      (_) async => Resultado(dato: _franjas, fecha: _ahora, vigente: true),
    );
  });

  tearDown(() => lista.close());

  void climaActual(Resultado<ClimaActual> resultado) =>
      when(() => clima.actual(any(), forzar: any(named: 'forzar')))
          .thenAnswer((_) async => resultado);

  Future<PanelVm> abrir(
    WidgetTester tester,
    List<Parcela> parcelasIniciales, {
    ConectividadServicio? conectividad,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final vm = PanelVm(
      parcelas: parcelas,
      clima: clima,
      preferencias: preferencias,
      conectividad: conectividad,
      reloj: () => _ahora,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaApp.claro,
        home: ChangeNotifierProvider.value(
          value: vm,
          child: const PanelPantalla(),
        ),
      ),
    );
    lista.add(parcelasIniciales);
    await tester.pumpAndSettle();
    return vm;
  }

  testWidgets('sin parcelas invita a registrar la primera', (tester) async {
    await abrir(tester, const []);
    expect(find.text(Textos.vacioParcelasTitulo), findsOneWidget);
    expect(find.text(Textos.registrarParcela), findsOneWidget);
  });

  testWidgets('muestra el clima vigente de la parcela (HU-07)', (tester) async {
    climaActual(Resultado(dato: _soleado, fecha: _ahora, vigente: true));
    await abrir(tester, const [_guayabal]);
    expect(find.text('El Guayabal'), findsOneWidget);
    expect(find.text('Jalapa · 1,380 msnm'), findsOneWidget);
    expect(find.text('24°'), findsWidgets);
    expect(find.text('Soleado'), findsOneWidget);
    expect(find.text('68%'), findsOneWidget);
    expect(find.text('18 NE'), findsOneWidget);
    expect(find.text('30%'), findsWidgets); // va a llover, próximas 12 h
    expect(find.text(Textos.horaPorHora), findsOneWidget);
    expect(find.text(Textos.ahora), findsOneWidget);
    expect(find.text('0 mm'), findsOneWidget);
    expect(find.text('5:52 a.m.'), findsOneWidget);
    expect(find.text('5:48 p.m.'), findsOneWidget);
    expect(find.textContaining('28°'), findsOneWidget); // máxima del ciclo
    expect(find.text(Textos.avisoApoyo), findsOneWidget);
    expect(find.text(Textos.sinInternetTitulo), findsNothing);
    expect(find.textContaining('actualizado hace un momento'), findsOneWidget);
  });

  testWidgets('sin internet: lo guardado, apagado y con su fecha (HU-15)', (
    tester,
  ) async {
    climaActual(
      Resultado(
        dato: _soleado,
        fecha: DateTime.utc(2026, 8, 12, 12),
        vigente: false,
        error: MotivoErrorClima.sinConexion,
      ),
    );
    await abrir(tester, const [_guayabal]);
    expect(find.text(Textos.sinInternetTitulo), findsOneWidget);
    expect(
      find.text(Textos.datosDel('12 de agosto, 6:00 a.m.')),
      findsOneWidget,
    );
    expect(find.text('24°'), findsWidgets);
    await tester.tap(find.text(Textos.intentarDeNuevo));
    await tester.pump();
    verify(() => clima.actual(_guayabal, forzar: true)).called(1);
  });

  testWidgets('sin ningún dato: causa probable e "Intentar de nuevo" (34)', (
    tester,
  ) async {
    climaActual(const Resultado.vacio(MotivoErrorClima.servicioCaido));
    await abrir(tester, const [_guayabal]);
    expect(find.text(Textos.sinDatosClimaTitulo), findsOneWidget);
    expect(
      find.text(Textos.causaErrorClima(MotivoErrorClima.servicioCaido)),
      findsOneWidget,
    );
    expect(find.text(Textos.intentarDeNuevo), findsOneWidget);
  });

  testWidgets('el selector cambia de parcela y la recuerda', (tester) async {
    climaActual(Resultado(dato: _soleado, fecha: _ahora, vigente: true));
    await abrir(tester, const [_guayabal, _joya]);
    await tester.tap(find.text('El Guayabal'));
    await tester.pumpAndSettle();
    expect(find.text(Textos.elegirParcela), findsOneWidget);
    await tester.tap(find.text('La Joya'));
    await tester.pumpAndSettle();
    expect(find.text('La Joya'), findsOneWidget);
    expect(preferencias.parcelaSeleccionada, 'p2');
    verify(() => clima.actual(_joya, forzar: false)).called(1);
  });

  testWidgets('abre en la última parcela elegida', (tester) async {
    preferencias.parcelaSeleccionada = 'p2';
    climaActual(Resultado(dato: _soleado, fecha: _ahora, vigente: true));
    await abrir(tester, const [_guayabal, _joya]);
    expect(find.text('La Joya'), findsOneWidget);
    expect(find.text('El Guayabal'), findsNothing);
  });

  test('frases y rumbos en palabras del campo', () {
    expect(Textos.fraseClima(800, esDeDia: true), 'Soleado');
    expect(Textos.fraseClima(800, esDeDia: false), 'Despejado');
    expect(Textos.fraseClima(502, esDeDia: true), 'Lluvia fuerte');
    expect(Textos.fraseClima(211, esDeDia: true), 'Tormenta');
    expect(Textos.rumbo(0), 'N');
    expect(Textos.rumbo(225), 'SO');
    expect(Textos.rumbo(350), 'N');
    expect(Textos.milimetros(0), '0 mm');
    expect(Textos.milimetros(2.5), '2.5 mm');
    expect(
      Textos.actualizadoHace(const Duration(minutes: 5)),
      'Datos de OpenWeather · actualizado hace 5 minutos',
    );
  });

  group('sin conexión (HU-15)', () {
    late StreamController<bool> red;
    late _RedFalsa conectividad;

    setUp(() {
      red = StreamController<bool>.broadcast();
      conectividad = _RedFalsa();
      when(() => conectividad.cambios).thenAnswer((_) => red.stream);
    });

    tearDown(() => red.close());

    testWidgets(
      'sin red en el teléfono se ve el banner, aun con dato vigente',
      (tester) async {
        when(conectividad.hayRed).thenAnswer((_) async => false);
        climaActual(Resultado(dato: _soleado, fecha: _ahora, vigente: true));
        await abrir(tester, const [_guayabal], conectividad: conectividad);
        expect(find.text(Textos.sinInternetTitulo), findsOneWidget);
        expect(
          find.text(Textos.datosDel('3 de octubre, 12:00 p.m.')),
          findsNothing,
        );
      },
    );

    testWidgets('al volver la señal se actualiza solo lo vencido', (
      tester,
    ) async {
      when(conectividad.hayRed).thenAnswer((_) async => false);
      climaActual(
        Resultado(
          dato: _soleado,
          fecha: _ahora.subtract(const Duration(hours: 3)),
          vigente: false,
          error: MotivoErrorClima.sinConexion,
        ),
      );
      await abrir(tester, const [_guayabal], conectividad: conectividad);
      clearInteractions(clima);
      climaActual(Resultado(dato: _soleado, fecha: _ahora, vigente: true));

      red.add(true);
      await tester.pumpAndSettle();

      verify(() => clima.actual(_guayabal, forzar: false)).called(1);
      expect(find.text(Textos.sinInternetTitulo), findsNothing);
      expect(find.text(Textos.intentarDeNuevo), findsNothing);
    });

    testWidgets('con dato vigente, volver la señal no gasta consultas', (
      tester,
    ) async {
      when(conectividad.hayRed).thenAnswer((_) async => false);
      climaActual(Resultado(dato: _soleado, fecha: _ahora, vigente: true));
      await abrir(tester, const [_guayabal], conectividad: conectividad);
      clearInteractions(clima);

      red.add(true);
      await tester.pumpAndSettle();

      verifyNever(() => clima.actual(any(), forzar: any(named: 'forzar')));
    });

    testWidgets('al volver a la app se revisa la vigencia', (tester) async {
      when(conectividad.hayRed).thenAnswer((_) async => true);
      climaActual(Resultado(dato: _soleado, fecha: _ahora, vigente: true));
      final vm = await abrir(tester, const [
        _guayabal,
      ], conectividad: conectividad);
      clearInteractions(clima);

      await vm.alVolverALaApp();

      verify(() => clima.actual(_guayabal, forzar: false)).called(1);
    });
  });
}
