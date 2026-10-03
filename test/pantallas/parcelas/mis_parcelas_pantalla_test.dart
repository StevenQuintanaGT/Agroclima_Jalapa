import 'dart:async';

import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/parcela.dart';
import 'package:agroclima_jalapa/pantallas/parcelas/detalle_parcela_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/parcelas/detalle_parcela_vm.dart';
import 'package:agroclima_jalapa/pantallas/parcelas/mis_parcelas_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/parcelas/mis_parcelas_vm.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _ParcelasFalsas extends Mock implements ParcelasServicio {}

const _guayabal = Parcela(
  parcelaId: 'p1',
  usuarioId: 'u1',
  nombre: 'El Guayabal',
  municipio: Municipio.jalapa,
  cultivo: Cultivo.maiz,
  etapa: Etapa.floracion,
  latitud: 14.6339,
  longitud: -89.9889,
  altitud: 1380,
  area: 2,
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

Widget _mapaFalso({
  required double latitud,
  required double longitud,
  required bool puntoPuesto,
  required void Function(double latitud, double longitud) alMoverPin,
}) => const ColoredBox(color: Colors.green);

/// Abre "Mis parcelas" dentro de un enrutador mínimo. Las rutas de destino
/// solo muestran su dirección, para comprobar a dónde se fue.
Future<StreamController<List<Parcela>>> _abrir(
  WidgetTester tester,
  _ParcelasFalsas parcelas,
) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final lista = StreamController<List<Parcela>>.broadcast();
  addTearDown(lista.close);
  when(parcelas.misParcelas).thenAnswer((_) => lista.stream);
  final enrutador = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, estado) => ChangeNotifierProvider(
          create: (_) => MisParcelasVm(parcelas),
          child: const MisParcelasPantalla(),
        ),
      ),
      GoRoute(
        path: '/parcelas/nueva',
        builder: (_, _) => const Text('ruta nueva'),
      ),
      GoRoute(
        path: '/parcelas/:id',
        builder: (_, estado) => Text('ruta ${estado.uri}'),
        routes: [
          GoRoute(
            path: 'editar',
            builder: (_, estado) =>
                Text('ruta ${estado.uri} ${(estado.extra! as Parcela).nombre}'),
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(theme: TemaApp.claro, routerConfig: enrutador),
  );
  return lista;
}

void main() {
  late _ParcelasFalsas parcelas;

  setUp(() => parcelas = _ParcelasFalsas());

  testWidgets('mientras carga muestra el esqueleto', (tester) async {
    await _abrir(tester, parcelas);
    await tester.pump();
    expect(find.text(Textos.misParcelas), findsOneWidget);
    expect(find.text(Textos.agregarParcela), findsNothing);
  });

  testWidgets('sin parcelas: estado vacío con un solo botón (16)', (
    tester,
  ) async {
    final lista = await _abrir(tester, parcelas);
    lista.add(const []);
    await tester.pumpAndSettle();
    expect(find.text(Textos.vacioParcelasTitulo), findsOneWidget);
    expect(find.text(Textos.agregarParcela), findsNothing);
    await tester.tap(find.text(Textos.registrarParcela));
    await tester.pumpAndSettle();
    expect(find.text('ruta nueva'), findsOneWidget);
  });

  testWidgets('con parcelas: tarjetas, cantidad y "Agregar parcela" (14)', (
    tester,
  ) async {
    final lista = await _abrir(tester, parcelas);
    lista.add(const [_guayabal, _joya]);
    await tester.pumpAndSettle();
    expect(find.text(Textos.terrenosRegistrados(2)), findsOneWidget);
    expect(find.text('El Guayabal'), findsOneWidget);
    expect(find.text('Jalapa · Maíz'), findsOneWidget);
    expect(find.text('Mataquescuintla · ${Textos.sinSembrar}'), findsOneWidget);
    expect(find.text(Textos.agregarParcela), findsOneWidget);
  });

  testWidgets('tocar la tarjeta abre el detalle', (tester) async {
    final lista = await _abrir(tester, parcelas);
    lista.add(const [_guayabal]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('El Guayabal'));
    await tester.pumpAndSettle();
    expect(find.text('ruta /parcelas/p1'), findsOneWidget);
  });

  testWidgets('deslizar muestra "Editar", que abre la edición', (tester) async {
    final lista = await _abrir(tester, parcelas);
    lista.add(const [_guayabal]);
    await tester.pumpAndSettle();
    await tester.drag(find.text('El Guayabal'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Textos.editar));
    await tester.pumpAndSettle();
    expect(find.text('ruta /parcelas/p1/editar El Guayabal'), findsOneWidget);
  });

  testWidgets('"Borrar" pregunta; "No, quedarme" no borra', (tester) async {
    final lista = await _abrir(tester, parcelas);
    lista.add(const [_guayabal]);
    await tester.pumpAndSettle();
    await tester.drag(find.text('El Guayabal'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Textos.borrar));
    await tester.pumpAndSettle();
    expect(find.text(Textos.preguntaBorrar('El Guayabal')), findsOneWidget);
    expect(find.text(Textos.detalleBorrar), findsOneWidget);
    await tester.tap(find.text(Textos.noQuedarme));
    await tester.pumpAndSettle();
    verifyNever(() => parcelas.eliminar(any()));
  });

  testWidgets('"Sí, borrar" borra y lo confirma', (tester) async {
    when(() => parcelas.eliminar('p1')).thenAnswer((_) async => false);
    final lista = await _abrir(tester, parcelas);
    lista.add(const [_guayabal]);
    await tester.pumpAndSettle();
    await tester.drag(find.text('El Guayabal'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Textos.borrar));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Textos.siBorrar));
    await tester.pumpAndSettle();
    verify(() => parcelas.eliminar('p1')).called(1);
    expect(find.text(Textos.parcelaBorrada), findsOneWidget);
  });

  testWidgets('sin señal avisa que se terminará de borrar después', (
    tester,
  ) async {
    when(() => parcelas.eliminar('p1')).thenAnswer((_) async => true);
    final lista = await _abrir(tester, parcelas);
    lista.add(const [_guayabal]);
    await tester.pumpAndSettle();
    await tester.drag(find.text('El Guayabal'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Textos.borrar));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Textos.siBorrar));
    await tester.pumpAndSettle();
    expect(find.text(Textos.borradaSinSenal), findsOneWidget);
  });

  testWidgets('si falla la lectura ofrece intentar de nuevo', (tester) async {
    final lista = await _abrir(tester, parcelas);
    lista.addError(Exception('sin permiso'));
    await tester.pumpAndSettle();
    expect(find.text(Textos.errorParcelasTitulo), findsOneWidget);
    await tester.tap(find.text(Textos.intentarDeNuevo));
    lista.add(const [_guayabal]);
    await tester.pumpAndSettle();
    expect(find.text('El Guayabal'), findsOneWidget);
  });

  group('detalle (15)', () {
    Future<StreamController<Parcela?>> abrirDetalle(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      final parcela = StreamController<Parcela?>.broadcast();
      addTearDown(parcela.close);
      when(() => parcelas.observar('p1')).thenAnswer((_) => parcela.stream);
      final enrutador = GoRouter(
        initialLocation: '/lista',
        routes: [
          GoRoute(
            path: '/lista',
            builder: (context, _) => TextButton(
              onPressed: () => context.push('/parcelas/p1'),
              child: const Text('abrir'),
            ),
          ),
          GoRoute(
            path: '/parcelas/:id',
            builder: (context, estado) => ChangeNotifierProvider(
              create: (_) => DetalleParcelaVm(parcelas, 'p1'),
              child: const DetalleParcelaPantalla(constructorMapa: _mapaFalso),
            ),
            routes: [
              GoRoute(
                path: 'editar',
                builder: (_, estado) => Text('ruta ${estado.uri}'),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(theme: TemaApp.claro, routerConfig: enrutador),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      parcela.add(_guayabal);
      await tester.pumpAndSettle();
      return parcela;
    }

    testWidgets('muestra los datos de la parcela', (tester) async {
      await abrirDetalle(tester);
      expect(find.text('El Guayabal'), findsWidgets);
      expect(find.text('Maíz · Floreando'), findsOneWidget);
      expect(find.text('2 ${Textos.manzanas} · 1,380 msnm'), findsOneWidget);
      expect(find.text('14.6339, -89.9889'), findsOneWidget);
    });

    testWidgets('tocar un dato abre su paso para cambiarlo', (tester) async {
      await abrirDetalle(tester);
      await tester.tap(find.text('Maíz · Floreando'));
      await tester.pumpAndSettle();
      expect(find.text('ruta /parcelas/p1/editar?paso=2'), findsOneWidget);
    });

    testWidgets('"Sí, borrar" borra y vuelve atrás', (tester) async {
      when(() => parcelas.eliminar('p1')).thenAnswer((_) async => false);
      final parcela = await abrirDetalle(tester);
      await tester.tap(find.text(Textos.borrarParcela));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Textos.siBorrar));
      parcela.add(null);
      await tester.pumpAndSettle();
      verify(() => parcelas.eliminar('p1')).called(1);
      expect(find.text('abrir'), findsOneWidget);
      expect(find.text(Textos.parcelaNoExiste), findsNothing);
    });

    testWidgets('si la borraron en otro teléfono lo dice', (tester) async {
      final parcela = await abrirDetalle(tester);
      parcela.add(null);
      await tester.pumpAndSettle();
      expect(find.text(Textos.parcelaNoExiste), findsOneWidget);
    });
  });
}
