import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/alerta.dart';
import 'package:agroclima_jalapa/modelos/capa_clima.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/parcela.dart';
import 'package:agroclima_jalapa/pantallas/clima/mapa_clima_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/clima/mapa_clima_vm.dart';
import 'package:agroclima_jalapa/servicios/alertas_servicio.dart';
import 'package:agroclima_jalapa/servicios/clima_servicio.dart';
import 'package:agroclima_jalapa/servicios/conectividad_servicio.dart';
import 'package:agroclima_jalapa/servicios/openweather_cliente.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../apoyo/alertas_de_prueba.dart';
import '../../apoyo/preferencias_falsas.dart';

class _ParcelasFalsas extends Mock implements ParcelasServicio {}

class _AlertasFalsas extends Mock implements AlertasServicio {}

class _ClimaFalso extends Mock implements ClimaServicio {}

class _RedFalsa extends Mock implements ConectividadServicio {}

Parcela _parcela(String id, String nombre) => Parcela(
  parcelaId: id,
  usuarioId: 'ana',
  nombre: nombre,
  municipio: Municipio.jalapa,
  latitud: 14.63,
  longitud: -89.99,
  celdaClima: '14.65_-90.00',
);

void main() {
  setUpAll(() => registerFallbackValue(CapaClima.lluvia));

  late _ClimaFalso clima;

  MapaClimaVm crearVm({
    bool red = true,
    List<Alerta> alertas = const [],
    String? elegida,
  }) {
    final parcelas = _ParcelasFalsas();
    final servicioAlertas = _AlertasFalsas();
    final conectividad = _RedFalsa();
    clima = _ClimaFalso();
    when(parcelas.misParcelas).thenAnswer(
      (_) => Stream.value([
        _parcela('joya', 'La Joya'),
        _parcela('guayabal', 'El Guayabal'),
      ]),
    );
    when(servicioAlertas.misAlertas).thenAnswer((_) => Stream.value(alertas));
    when(conectividad.hayRed).thenAnswer((_) async => red);
    when(() => conectividad.cambios).thenAnswer((_) => const Stream.empty());
    when(() => clima.urlCapa(any())).thenAnswer(
      (i) =>
          'https://capa/${(i.positionalArguments.first as CapaClima).name}/{z}/{x}/{y}',
    );
    final preferencias = PreferenciasFalsas(parcelaSeleccionada: elegida);
    return MapaClimaVm(
      parcelas: parcelas,
      alertas: servicioAlertas,
      clima: clima,
      preferencias: preferencias,
      conectividad: conectividad,
      reloj: () => ahoraDePrueba,
    );
  }

  group('MapaClimaVm', () {
    test(
      'ninguna capa se carga sola; tocar la activa la quita (RT-04)',
      () async {
        final vm = crearVm();
        await Future<void>.delayed(Duration.zero);
        expect(vm.capa, isNull);
        expect(vm.urlCapa, isNull);
        verifyNever(() => clima.urlCapa(any()));
        vm.elegirCapa(CapaClima.lluvia);
        expect(vm.urlCapa, 'https://capa/lluvia/{z}/{x}/{y}');
        vm.elegirCapa(CapaClima.nubes);
        expect(vm.capa, CapaClima.nubes);
        vm.elegirCapa(CapaClima.nubes);
        expect(vm.capa, isNull);
      },
    );

    test('si falla la capa avisa una vez; al cambiar de capa se limpia', () {
      final vm = crearVm()..elegirCapa(CapaClima.calor);
      var avisos = 0;
      vm.addListener(() => avisos++);
      vm
        ..capaFallo()
        ..capaFallo();
      expect(vm.errorCapa, isTrue);
      expect(avisos, 1);
      vm.elegirCapa(CapaClima.viento);
      expect(vm.errorCapa, isFalse);
    });

    test('pin del color del aviso activo más alto de cada parcela', () async {
      final vm = crearVm(
        alertas: [
          alertaDePrueba(
            id: 'a',
            parcelaId: 'guayabal',
            nivel: NivelSeveridad.preventiva,
            tipo: TipoRiesgo.vientoFuerte,
          ),
          alertaDePrueba(
            id: 'b',
            parcelaId: 'guayabal',
            nivel: NivelSeveridad.critica,
          ),
          alertaDePrueba(
            id: 'c',
            parcelaId: 'joya',
            nivel: NivelSeveridad.critica,
            dia: 2,
          ),
        ],
      );
      await Future<void>.delayed(Duration.zero);
      // La de La Joya ya pasó: su pin queda verde.
      expect(vm.nivelPorParcela, {'guayabal': NivelSeveridad.critica});
    });

    test('"Mi parcela" es la elegida en el panel o la primera', () async {
      final vm = crearVm(elegida: 'guayabal');
      await Future<void>.delayed(Duration.zero);
      expect(vm.miParcela?.nombre, 'El Guayabal');
      expect(crearVm().miParcela, isNull);
    });

    test('"Ver más claro" no deja la capa invisible', () {
      final vm = crearVm()..cambiarOpacidad(0);
      expect(vm.opacidad, 0.2);
    });
  });

  group('pantalla', () {
    Future<List<String?>> abrir(WidgetTester tester, {bool red = true}) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      final urls = <String?>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaApp.claro,
          home: ChangeNotifierProvider(
            create: (_) => crearVm(red: red),
            child: MapaClimaPantalla(
              constructorMapa:
                  ({
                    required List<Parcela> parcelas,
                    required Map<String, NivelSeveridad> niveles,
                    required String? urlCapa,
                    required bool tenirCapa,
                    required double opacidad,
                    required VoidCallback alFallarCapa,
                    required MapController controlador,
                    required void Function(Parcela) alTocarParcela,
                  }) {
                    urls.add(urlCapa);
                    return Center(child: Text('${parcelas.length} parcelas'));
                  },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return urls;
    }

    testWidgets('sin capa: indicación; con Lluvia: leyenda y capa', (
      tester,
    ) async {
      final urls = await abrir(tester);
      expect(find.text(Textos.mapaClima), findsOneWidget);
      expect(find.text('2 parcelas'), findsOneWidget);
      expect(find.text(Textos.elijaCapa), findsOneWidget);
      expect(urls.last, isNull);

      await tester.tap(find.text('Lluvia'));
      await tester.pumpAndSettle();
      expect(find.text(Textos.queSignificanColores), findsOneWidget);
      expect(find.text('Poca lluvia'), findsOneWidget);
      expect(find.text('Lluvia fuerte'), findsOneWidget);
      expect(find.text(Textos.verMasClaro), findsOneWidget);
      expect(urls.last, 'https://capa/lluvia/{z}/{x}/{y}');
    });

    testWidgets('sin internet lo dice', (tester) async {
      await abrir(tester, red: false);
      expect(find.text(Textos.sinInternetMapa), findsOneWidget);
    });
  });

  test('teselas de OpenWeather del plan gratuito, una plantilla por capa', () {
    final cliente = OpenWeatherCliente(clave: 'k');
    expect(
      cliente.urlTeselas(CapaClima.lluvia),
      'https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid=k',
    );
    expect(cliente.urlTeselas(CapaClima.viento), contains('/wind_new/'));
    expect(cliente.urlTeselas(CapaClima.calor), contains('/temp_new/'));
    expect(cliente.urlTeselas(CapaClima.nubes), contains('/clouds_new/'));
  });
}
