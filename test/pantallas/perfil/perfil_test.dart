import 'dart:async';

import 'package:agroclima_jalapa/config/constantes.dart';
import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/parcela.dart';
import 'package:agroclima_jalapa/modelos/usuario.dart';
import 'package:agroclima_jalapa/pantallas/perfil/acerca_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/perfil/ajustes_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/perfil/ajustes_vm.dart';
import 'package:agroclima_jalapa/pantallas/perfil/ayuda_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/perfil/perfil_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/perfil/perfil_vm.dart';
import 'package:agroclima_jalapa/repositorios/auth_repositorio.dart';
import 'package:agroclima_jalapa/repositorios/usuario_repositorio.dart';
import 'package:agroclima_jalapa/servicios/conectividad_servicio.dart';
import 'package:agroclima_jalapa/servicios/cuenta_servicio.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:agroclima_jalapa/servicios/perfil_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _AuthFalso extends Mock implements AuthRepositorio {}

class _UsuariosFalso extends Mock implements UsuarioRepositorio {}

class _CuentaFalsa extends Mock implements CuentaServicio {}

class _ParcelasFalsas extends Mock implements ParcelasServicio {}

class _ConectividadFalsa extends Mock implements ConectividadServicio {}

Parcela _parcela(String id, Municipio municipio) => Parcela(
  parcelaId: id,
  usuarioId: 'juan',
  nombre: id,
  municipio: municipio,
  latitud: 14.63,
  longitud: -89.99,
  celdaClima: '14.65_-90.00',
);

void main() {
  late _UsuariosFalso usuarios;
  late _CuentaFalsa cuenta;
  late _ParcelasFalsas parcelas;
  late _ConectividadFalsa conectividad;
  late StreamController<Usuario?> perfilEnVivo;
  late PerfilServicio perfil;

  const juan = Usuario(
    uid: 'juan',
    nombre: 'Juan López',
    correo: 'juan.lopez@correo.com',
    telefono: '+50245829385',
  );

  setUp(() {
    final auth = _AuthFalso();
    usuarios = _UsuariosFalso();
    cuenta = _CuentaFalsa();
    parcelas = _ParcelasFalsas();
    conectividad = _ConectividadFalsa();
    perfilEnVivo = StreamController<Usuario?>.broadcast();
    when(() => auth.uidActual).thenReturn('juan');
    when(() => auth.cambiosDeSesion).thenAnswer((_) => const Stream.empty());
    when(() => usuarios.observarPerfil('juan'))
        .thenAnswer((_) => perfilEnVivo.stream);
    when(
      () => usuarios.guardarAjustes(
        any(),
        unidadTemperatura: any(named: 'unidadTemperatura'),
        unidadArea: any(named: 'unidadArea'),
        temaOscuro: any(named: 'temaOscuro'),
        ahorroDatos: any(named: 'ahorroDatos'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => usuarios.guardarDatos(
        any(),
        nombre: any(named: 'nombre'),
        telefono: any(named: 'telefono'),
      ),
    ).thenAnswer((_) async {});
    when(() => parcelas.misParcelas()).thenAnswer(
      (_) => Stream.value([
        _parcela('La Joya', Municipio.jalapa),
        _parcela('El Guayabal', Municipio.jalapa),
        _parcela('El Durazno', Municipio.monjas),
      ]),
    );
    when(() => cuenta.cerrarSesion()).thenAnswer((_) async {});
    when(() => cuenta.eliminarCuenta()).thenAnswer((_) async {});
    when(() => conectividad.hayRed()).thenAnswer((_) async => true);
    perfil = PerfilServicio(auth: auth, usuarios: usuarios);
  });

  tearDown(() => perfil.dispose());

  Future<void> abrir(WidgetTester tester, Widget pantalla) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaApp.claro,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  PerfilVm(cuenta: cuenta, perfil: perfil, parcelas: parcelas),
            ),
            ChangeNotifierProvider(
              create: (_) => AjustesVm(
                perfil: perfil,
                cuenta: cuenta,
                conectividad: conectividad,
              ),
            ),
          ],
          child: pantalla,
        ),
      ),
    );
    perfilEnVivo.add(juan);
    await tester.pumpAndSettle();
  }

  group('Perfil (28)', () {
    testWidgets('iniciales, nombre, correo y dónde tiene sus parcelas', (
      tester,
    ) async {
      await abrir(tester, const PerfilPantalla());
      expect(find.text('JL'), findsOneWidget);
      expect(find.text('Juan López'), findsOneWidget);
      expect(find.text('juan.lopez@correo.com'), findsOneWidget);
      expect(find.text('Jalapa · 3 parcelas'), findsOneWidget);
      for (final texto in [
        Textos.misParcelas,
        Textos.misAvisos,
        Textos.ajustes,
        Textos.ayuda,
        Textos.cerrarSesion,
      ]) {
        expect(find.text(texto), findsOneWidget);
      }
    });

    testWidgets('cambiar mis datos valida el teléfono y guarda con +502', (
      tester,
    ) async {
      await abrir(tester, const PerfilPantalla());
      await tester.tap(find.text(Textos.cambiarMisDatos));
      await tester.pumpAndSettle();
      expect(find.text('45829385'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '1234');
      await tester.tap(find.text(Textos.guardarCambios));
      await tester.pumpAndSettle();
      expect(find.text(Textos.errorTelefono), findsOneWidget);
      verifyNever(
        () => usuarios.guardarDatos(
          any(),
          nombre: any(named: 'nombre'),
          telefono: any(named: 'telefono'),
        ),
      );

      await tester.enterText(find.byType(TextField).last, '5512 3456');
      await tester.tap(find.text(Textos.guardarCambios));
      await tester.pumpAndSettle();
      verify(
        () => usuarios.guardarDatos(
          'juan',
          nombre: 'Juan López',
          telefono: '+50255123456',
        ),
      ).called(1);
      expect(find.text(Textos.datosGuardados), findsOneWidget);
    });
  });

  group('Ajustes (29)', () {
    testWidgets('°F, hectáreas, pantalla oscura y ahorro se guardan', (
      tester,
    ) async {
      await abrir(tester, const AjustesPantalla());
      await tester.tap(find.text(Textos.fahrenheit));
      await tester.tap(find.text(Textos.hectareasCorto));
      await tester.tap(find.text(Textos.pantallaOscura));
      await tester.tap(find.text(Textos.ahorrarDatos));
      await tester.pumpAndSettle();
      verify(() => usuarios.guardarAjustes('juan', unidadTemperatura: 'F'));
      verify(() => usuarios.guardarAjustes('juan', unidadArea: 'hectarea'));
      verify(() => usuarios.guardarAjustes('juan', temaOscuro: true));
      verify(() => usuarios.guardarAjustes('juan', ahorroDatos: true));
    });

    testWidgets('lo guardado se ve elegido', (tester) async {
      await abrir(tester, const AjustesPantalla());
      perfilEnVivo.add(
        const Usuario(
          uid: 'juan',
          nombre: 'Juan',
          correo: 'j@c.com',
          unidadTemperatura: 'F',
          ahorroDatos: true,
        ),
      );
      await tester.pumpAndSettle();
      bool elegida(String etiqueta) => tester
          .widget<Semantics>(
            find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.label == etiqueta,
            ),
          )
          .properties
          .selected!;
      expect(elegida('${Textos.temperatura}: ${Textos.fahrenheit}'), isTrue);
      expect(elegida('${Textos.temperatura}: ${Textos.celsius}'), isFalse);
      expect(elegida('${Textos.terreno}: ${Textos.manzanasCorto}'), isTrue);
      final interruptores = tester.widgetList<Switch>(find.byType(Switch));
      expect(interruptores.map((s) => s.value), [false, true]);
    });

    testWidgets('eliminar la cuenta pide confirmar dos veces', (tester) async {
      await abrir(tester, const AjustesPantalla());
      await tester.tap(find.text(Textos.eliminarMiCuenta));
      await tester.pumpAndSettle();
      expect(find.text(Textos.eliminarCuentaTitulo), findsOneWidget);
      await tester.tap(find.text(Textos.siSeguir));
      await tester.pumpAndSettle();
      expect(find.text(Textos.eliminarCuentaSeguro), findsOneWidget);
      verifyNever(() => cuenta.eliminarCuenta());
      await tester.tap(find.text(Textos.siEliminar));
      await tester.pumpAndSettle();
      verify(() => cuenta.eliminarCuenta()).called(1);
    });

    testWidgets('"No, quedarme" no elimina nada', (tester) async {
      await abrir(tester, const AjustesPantalla());
      await tester.tap(find.text(Textos.eliminarMiCuenta));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Textos.noQuedarme));
      await tester.pumpAndSettle();
      expect(find.text(Textos.eliminarCuentaSeguro), findsNothing);
      verifyNever(() => cuenta.eliminarCuenta());
    });

    testWidgets('sin señal no se intenta y se dice por qué', (tester) async {
      when(() => conectividad.hayRed()).thenAnswer((_) async => false);
      await abrir(tester, const AjustesPantalla());
      await tester.tap(find.text(Textos.eliminarMiCuenta));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Textos.siSeguir));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Textos.siEliminar));
      await tester.pumpAndSettle();
      verifyNever(() => cuenta.eliminarCuenta());
      expect(find.text(Textos.eliminarSinSenal), findsOneWidget);
    });
  });

  testWidgets('Ayuda (30): una pregunta abierta a la vez y el glosario', (
    tester,
  ) async {
    await abrir(tester, const AyudaPantalla());
    final (primera, respuesta1) = Textos.preguntas[0];
    final (segunda, respuesta2) = Textos.preguntas[1];
    expect(find.text(respuesta1), findsOneWidget);
    expect(find.text(respuesta2), findsNothing);
    await tester.tap(find.text(segunda));
    await tester.pumpAndSettle();
    expect(find.text(respuesta2), findsOneWidget);
    expect(find.text(respuesta1), findsNothing);
    await tester.tap(find.text(primera));
    await tester.pumpAndSettle();
    expect(find.text(respuesta1), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(Textos.helada),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(Textos.heladaDetalle), findsOneWidget);
  });

  testWidgets('Acerca de (31): versión, fuentes y términos', (tester) async {
    await abrir(tester, const AcercaPantalla());
    expect(find.text(Textos.version(Constantes.versionApp)), findsOneWidget);
    expect(find.text(Textos.fuentesMapas), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(Textos.terminosYPrivacidad),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(Textos.noEsOficial), findsOneWidget);
    await tester.tap(find.text(Textos.terminosYPrivacidad));
    await tester.pumpAndSettle();
    expect(find.text(Textos.terminos.first), findsOneWidget);
  });
}
