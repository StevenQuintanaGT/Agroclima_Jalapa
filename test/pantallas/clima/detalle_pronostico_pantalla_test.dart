import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/clima_actual.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/franja_pronostico.dart';
import 'package:agroclima_jalapa/modelos/parcela.dart';
import 'package:agroclima_jalapa/modelos/resultado.dart';
import 'package:agroclima_jalapa/pantallas/clima/detalle_pronostico_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/clima/detalle_pronostico_vm.dart';
import 'package:agroclima_jalapa/servicios/clima_servicio.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _ParcelasFalsas extends Mock implements ParcelasServicio {}

class _ClimaFalso extends Mock implements ClimaServicio {}

/// 3 de octubre de 2026 (sábado), 00:00 en Guatemala.
final _inicio = DateTime.utc(2026, 10, 3, 6);

const _parcela = Parcela(
  parcelaId: 'p1',
  usuarioId: 'u1',
  nombre: 'El Guayabal',
  municipio: Municipio.jalapa,
  latitud: 14.63,
  longitud: -89.99,
  celdaClima: '14.65_-90.00',
);

/// 2 días: el sábado frío de madrugada y sin lluvia; el domingo con 6 mm.
final _franjas = [
  for (var i = 0; i < 16; i++)
    FranjaPronostico(
      fechaHora: _inicio.add(Duration(hours: 3 * i)),
      temperatura: [14.0, 13.0, 18.0, 25.0, 27.0, 22.0, 18.0, 16.0][i % 8],
      temperaturaMinima: 12,
      temperaturaMaxima: 28,
      humedadRelativa: 70,
      lluvia3h: i == 12 ? 6 : 0,
      velocidadViento: i == 4 ? 32 : 10,
      probabilidadLluvia: 0.2,
      codigoClima: 800,
    ),
];

void main() {
  setUpAll(() async {
    registerFallbackValue(_parcela);
    await initializeDateFormatting('es');
  });

  Future<void> abrir(WidgetTester tester, {String? dia}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final parcelas = _ParcelasFalsas();
    final clima = _ClimaFalso();
    when(() => parcelas.observar('p1'))
        .thenAnswer((_) => Stream.value(_parcela));
    when(() => clima.proximosDias('p1'))
        .thenAnswer((_) => Stream.value(const []));
    when(() => clima.porHoras(any())).thenAnswer(
      (_) async => Resultado(dato: _franjas, fecha: _inicio, vigente: true),
    );
    when(() => clima.actual(any())).thenAnswer(
      (_) async => Resultado(
        dato: ClimaActual(
          fechaHora: _inicio,
          temperatura: 14,
          sensacionTermica: 14,
          humedadRelativa: 70,
          lluviaUltimaHora: 0,
          velocidadViento: 5,
          codigoClima: 800,
          salidaSol: DateTime.utc(2026, 10, 3, 11, 42),
          puestaSol: DateTime.utc(2026, 10, 4, 0, 24),
        ),
        fecha: _inicio,
        vigente: true,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaApp.claro,
        home: ChangeNotifierProvider(
          create: (_) => DetallePronosticoVm(
            parcelas: parcelas,
            clima: clima,
            parcelaId: 'p1',
            diaInicial: dia,
            reloj: () => _inicio,
          ),
          child: const DetallePronosticoPantalla(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hoy: frase de la hora más fría, lluvia y resumen', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.text(Textos.pronosticoDetallado), findsOneWidget);
    expect(find.text('Sábado'), findsOneWidget);
    expect(find.text(Textos.hoy), findsOneWidget);
    expect(find.text('Domingo'), findsOneWidget);
    expect(find.text('Lo más frío será a las 3 de la mañana'), findsOneWidget);
    expect(find.text('No se espera lluvia hoy'), findsOneWidget);
    expect(find.text('32 km/h'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('5:42 a.m. · 6:24 p.m.'), findsOneWidget);
  });

  testWidgets('al elegir otro día cambian las frases y no hay sol', (
    tester,
  ) async {
    await abrir(tester);
    await tester.tap(find.text('Domingo'));
    await tester.pumpAndSettle();
    expect(
      find.text('Total esperado ese día: 6 mm — lluvia ligera'),
      findsOneWidget,
    );
    expect(find.text(Textos.saleYSePone), findsNothing);
  });

  testWidgets('abre directo en el día pedido desde el panel', (tester) async {
    await abrir(tester, dia: '20261004');
    expect(
      find.text('Total esperado ese día: 6 mm — lluvia ligera'),
      findsOneWidget,
    );
  });
}
