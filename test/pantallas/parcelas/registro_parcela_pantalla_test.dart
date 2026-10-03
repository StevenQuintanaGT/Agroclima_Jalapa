import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/pantallas/parcelas/registro_parcela_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/parcelas/registro_parcela_vm.dart';
import 'package:agroclima_jalapa/servicios/busqueda_lugares_servicio.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:agroclima_jalapa/servicios/ubicacion_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../apoyo/limites.dart';

class _ParcelasFalsas extends Mock implements ParcelasServicio {}

class _UbicacionFalsa extends Mock implements UbicacionServicio {}

class _BusquedaFalsa extends Mock implements BusquedaLugaresServicio {}

/// En las pruebas no hay Google Maps: un botón hace de "tocar el mapa".
Widget _mapaFalso({
  required double latitud,
  required double longitud,
  required bool puntoPuesto,
  required void Function(double latitud, double longitud) alMoverPin,
}) => Center(
  child: TextButton(
    key: const ValueKey('mapa'),
    onPressed: () => alMoverPin(cabeceraJalapa.lat, cabeceraJalapa.lon),
    child: const Text('mapa de prueba'),
  ),
);

Future<RegistroParcelaVm> _abrir(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final parcelas = _ParcelasFalsas();
  when(() => parcelas.validacion).thenReturn(limitesReales());
  when(() => parcelas.nombresUsados()).thenAnswer((_) async => const []);
  final vm = RegistroParcelaVm(
    parcelas: parcelas,
    ubicacion: _UbicacionFalsa(),
    busqueda: _BusquedaFalsa(),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: TemaApp.claro,
      home: ChangeNotifierProvider.value(
        value: vm,
        child: const RegistroParcelaPantalla(constructorMapa: _mapaFalso),
      ),
    ),
  );
  return vm;
}

Future<void> _siguiente(WidgetTester tester) async {
  await tester.tap(find.text(Textos.siguiente));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('paso 1 muestra los 7 municipios a la vez', (tester) async {
    await _abrir(tester);
    expect(find.text(Textos.pasoDe(1, 4)), findsOneWidget);
    for (final nombre in [
      'Jalapa',
      'San Pedro Pinula',
      'San Luis Jilotepeque',
      'San Manuel Chaparrón',
      'San Carlos Alzatate',
      'Monjas',
      'Mataquescuintla',
    ]) {
      expect(find.text(nombre), findsOneWidget);
    }
  });

  testWidgets('sin datos, "Siguiente" muestra lo que falta', (tester) async {
    await _abrir(tester);
    await _siguiente(tester);
    expect(find.text(Textos.errorNombreParcelaVacio), findsOneWidget);
    expect(
      find.text(Textos.errorElijaMunicipio, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text(Textos.pasoDe(1, 4)), findsOneWidget);
  });

  testWidgets('recorre los 4 pasos y "Cambiar" vuelve a la revisión', (
    tester,
  ) async {
    final vm = await _abrir(tester);
    await tester.enterText(find.byType(TextFormField), 'El Guayabal');
    await tocar(tester, 'Jalapa');
    await _siguiente(tester);

    expect(find.text(Textos.pregCultivo), findsOneWidget);
    await tocar(tester, 'Café');
    await tocar(tester, 'Floreando');
    await _siguiente(tester);

    expect(find.text(Textos.tituloPaso3), findsOneWidget);
    expect(find.text(Textos.arrastrePin), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mapa')));
    await tester.pumpAndSettle();
    expect(find.text('14.6339, -89.9889'), findsOneWidget);
    await _siguiente(tester);

    expect(find.text(Textos.tituloPaso4), findsOneWidget);
    expect(find.text('El Guayabal'), findsOneWidget);
    expect(find.text('Café · Floreando'), findsOneWidget);
    expect(find.text(Textos.guardarParcela), findsOneWidget);

    await tester.tap(find.text(Textos.cambiar).at(2)); // cultivo
    await tester.pumpAndSettle();
    expect(vm.paso, 2);
    await tocar(tester, 'Maíz');
    await tocar(tester, 'Cosecha');
    await _siguiente(tester);
    expect(find.text('Maíz · Cosecha'), findsOneWidget);
  });

  testWidgets('"Atrás" en la barra retrocede un paso', (tester) async {
    final vm = await _abrir(tester);
    await tester.enterText(find.byType(TextFormField), 'El Guayabal');
    await tocar(tester, 'Jalapa');
    await _siguiente(tester);
    expect(vm.paso, 2);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(vm.paso, 1);
  });
}

/// Desplaza hasta el texto y lo toca (los pasos son listas largas).
Future<void> tocar(WidgetTester tester, String texto) async {
  final objetivo = find.text(texto);
  await tester.ensureVisible(objetivo.first);
  await tester.pumpAndSettle();
  await tester.tap(objetivo.first);
  await tester.pumpAndSettle();
}
