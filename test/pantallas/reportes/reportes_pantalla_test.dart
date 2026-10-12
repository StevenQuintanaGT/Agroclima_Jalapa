import 'dart:typed_data';

import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/parcela.dart';
import 'package:agroclima_jalapa/modelos/registro_dia.dart';
import 'package:agroclima_jalapa/pantallas/reportes/reportes_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/reportes/reportes_vm.dart';
import 'package:agroclima_jalapa/servicios/alertas_servicio.dart';
import 'package:agroclima_jalapa/servicios/compartir_servicio.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:agroclima_jalapa/servicios/reportes_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../apoyo/alertas_de_prueba.dart';
import '../../apoyo/preferencias_falsas.dart';

class _ParcelasFalsas extends Mock implements ParcelasServicio {}

class _AlertasFalsas extends Mock implements AlertasServicio {}

class _ReportesFalsos extends Mock implements ReportesServicio {}

class _CompartirFalso extends Mock implements CompartirServicio {}

const _parcela = Parcela(
  parcelaId: 'guayabal',
  usuarioId: 'ana',
  nombre: 'El Guayabal',
  municipio: Municipio.jalapa,
  latitud: 14.63,
  longitud: -89.99,
  celdaClima: '14.65_-90.00',
  cultivo: Cultivo.maiz,
);

const _registros = [
  RegistroDia(
    fecha: '20261001',
    temperatura: 19,
    temperaturaMinima: 11,
    temperaturaMaxima: 25,
    precipitacion: 12,
  ),
  RegistroDia(
    fecha: '20261002',
    temperatura: 21,
    temperaturaMinima: 16,
    temperaturaMaxima: 29,
    precipitacion: 34,
  ),
];

void main() {
  late _ReportesFalsos reportes;
  late _CompartirFalso compartir;

  setUpAll(() async {
    await initializeDateFormatting('es');
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(Periodo.ultimosDias(7, ahoraDePrueba));
  });

  Future<void> abrir(
    WidgetTester tester, {
    List<Parcela> parcelas = const [_parcela],
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final servicioParcelas = _ParcelasFalsas();
    final alertas = _AlertasFalsas();
    reportes = _ReportesFalsos();
    compartir = _CompartirFalso();
    when(servicioParcelas.misParcelas)
        .thenAnswer((_) => Stream.value(parcelas));
    when(alertas.misAlertas).thenAnswer(
      (_) => Stream.value([
        alertaDePrueba(
          parcelaId: 'guayabal',
          dia: 2,
          tipo: TipoRiesgo.lluviaIntensa,
          esperado: 34,
          umbral: 30,
        ),
      ]),
    );
    when(() => reportes.registros(any(), any()))
        .thenAnswer((_) => Stream.value(_registros));
    when(
      () => compartir.compartirArchivo(
        any(),
        nombre: any(named: 'nombre'),
        tipoMime: any(named: 'tipoMime'),
      ),
    ).thenAnswer((_) async {});
    when(() => compartir.imprimirPdf(any(), nombre: any(named: 'nombre')))
        .thenAnswer((_) async => false);
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaApp.claro,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ChangeNotifierProvider(
          create: (_) => ReportesVm(
            parcelas: servicioParcelas,
            alertas: alertas,
            reportes: reportes,
            compartir: compartir,
            preferencias: PreferenciasFalsas(),
            reloj: () => ahoraDePrueba,
          ),
          child: const ReportesPantalla(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('4 indicadores y las frases de las gráficas', (tester) async {
    await abrir(tester);
    expect(find.text(Textos.resumen), findsOneWidget);
    expect(find.text('El Guayabal'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == '2 días con lluvia',
      ),
      findsOneWidget,
    );
    expect(find.text('días con lluvia'), findsOneWidget);
    expect(find.text('11 °C'), findsOneWidget);
    expect(find.text('46 mm'), findsOneWidget);
    expect(find.text('aviso de peligro'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(Textos.lluviaPorDia),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('La noche más fría fue el jueves 1, con 11 °C.'),
      findsOneWidget,
    );
    expect(find.text('Llovió más el viernes 2: 34 mm.'), findsOneWidget);
  });

  testWidgets('30 días pide el período nuevo', (tester) async {
    await abrir(tester);
    await tester.tap(find.text(Textos.treintaDias));
    await tester.pumpAndSettle();
    final periodo =
        verify(() => reportes.registros('guayabal', captureAny())).captured.last
            as Periodo;
    expect(periodo.cantidadDias, 30);
    expect(
      find.text('Del 6 de septiembre al 5 de octubre de 2026'),
      findsOneWidget,
    );
  });

  testWidgets('Guardar o enviar: 3 formatos; Excel se comparte como .xlsx', (
    tester,
  ) async {
    await abrir(tester);
    await tester.tap(find.text(Textos.enviar));
    await tester.pumpAndSettle();
    expect(find.text(Textos.guardarOEnviar), findsOneWidget);
    expect(find.text(Textos.archivoPdf), findsOneWidget);
    expect(find.text(Textos.hojaExcel), findsOneWidget);
    expect(find.text(Textos.archivoCsv), findsOneWidget);
    await tester.tap(find.text(Textos.hojaExcel));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(Textos.compartir));
    await tester.tap(find.text(Textos.compartir));
    await tester.pumpAndSettle();
    final nombre =
        verify(
              () => compartir.compartirArchivo(
                any(),
                nombre: captureAny(named: 'nombre'),
                tipoMime: any(named: 'tipoMime'),
              ),
            ).captured.single
            as String;
    expect(nombre, 'agroclima_el-guayabal_20260929_20261005.xlsx');
  });

  testWidgets('sin impresora lo dice y ofrece compartir', (tester) async {
    await abrir(tester);
    await tester.tap(find.text(Textos.enviar));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(Textos.imprimir));
    await tester.tap(find.text(Textos.imprimir));
    await tester.pumpAndSettle();
    verify(() => compartir.imprimirPdf(any(), nombre: any(named: 'nombre')))
        .called(1);
    expect(find.text(Textos.noSePudoImprimir), findsOneWidget);
  });

  testWidgets('sin parcelas invita a registrar una', (tester) async {
    await abrir(tester, parcelas: const []);
    expect(find.text(Textos.sinParcelasReporte), findsOneWidget);
  });
}
