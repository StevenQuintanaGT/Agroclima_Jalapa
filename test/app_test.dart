import 'package:agroclima_jalapa/app.dart';
import 'package:agroclima_jalapa/config/rutas.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/pantallas/acceso/bienvenida_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/acceso/inicio_sesion_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/acceso/registro_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/acceso/splash_pantalla.dart';
import 'package:agroclima_jalapa/servicios/clima_servicio.dart';
import 'package:agroclima_jalapa/servicios/conectividad_servicio.dart';
import 'package:agroclima_jalapa/servicios/cuenta_servicio.dart';
import 'package:agroclima_jalapa/servicios/notificaciones_servicio.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:agroclima_jalapa/servicios/ubicacion_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'apoyo/preferencias_falsas.dart';

class _CuentaFalsa extends Mock implements CuentaServicio {}

class _UbicacionFalsa extends Mock implements UbicacionServicio {}

class _AvisosFalsos extends Mock implements NotificacionesServicio {}

class _ParcelasFalsas extends Mock implements ParcelasServicio {}

class _ClimaFalso extends Mock implements ClimaServicio {}

class _RedFalsa extends Mock implements ConectividadServicio {}

ConectividadServicio _conRed() {
  final red = _RedFalsa();
  when(red.hayRed).thenAnswer((_) async => true);
  when(() => red.cambios).thenAnswer((_) => const Stream.empty());
  return red;
}

ParcelasServicio _sinParcelas() {
  final parcelas = _ParcelasFalsas();
  when(parcelas.misParcelas).thenAnswer((_) => Stream.value(const []));
  return parcelas;
}

Future<ValueNotifier<bool>> _abrir(
  WidgetTester tester, {
  required bool sesion,
  PreferenciasFalsas? preferencias,
}) async {
  final haySesion = ValueNotifier<bool>(sesion);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<CuentaServicio>.value(value: _CuentaFalsa()),
        Provider<UbicacionServicio>.value(value: _UbicacionFalsa()),
        Provider<NotificacionesServicio>.value(value: _AvisosFalsos()),
        Provider<ParcelasServicio>.value(value: _sinParcelas()),
        Provider<ClimaServicio>.value(value: _ClimaFalso()),
        Provider<ConectividadServicio>.value(value: _conRed()),
      ],
      child: AgroClimaApp(
        enrutador: crearEnrutador(
          haySesion: haySesion,
          preferencias:
              preferencias ?? PreferenciasFalsas(permisosOfrecidos: true),
        ),
      ),
    ),
  );
  // Pasa el splash (1.2 s).
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
  return haySesion;
}

void main() {
  testWidgets('arranca en el splash con la marca', (tester) async {
    await tester.pumpWidget(
      Provider<CuentaServicio>.value(
        value: _CuentaFalsa(),
        child: AgroClimaApp(
          enrutador: crearEnrutador(
            haySesion: ValueNotifier(false),
            preferencias: PreferenciasFalsas(),
          ),
        ),
      ),
    );
    expect(find.byType(SplashPantalla), findsOneWidget);
    expect(find.text(Textos.lema), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
  });

  testWidgets('primera vez sin sesión: splash → bienvenida', (tester) async {
    await _abrir(tester, sesion: false, preferencias: PreferenciasFalsas());
    expect(find.byType(BienvenidaPantalla), findsOneWidget);
  });

  testWidgets('ya vio la bienvenida: splash → entrar', (tester) async {
    await _abrir(
      tester,
      sesion: false,
      preferencias: PreferenciasFalsas(bienvenidaVista: true),
    );
    expect(find.byType(InicioSesionPantalla), findsOneWidget);
  });

  testWidgets('con sesión: splash → Inicio con los 5 destinos', (tester) async {
    await _abrir(tester, sesion: true);
    for (final etiqueta in [
      Textos.navInicio,
      Textos.navMapa,
      Textos.navAlertas,
      Textos.navReportes,
      Textos.navPerfil,
    ]) {
      expect(find.text(etiqueta), findsWidgets);
    }
  });

  testWidgets('"Empezar" en la bienvenida lleva a crear cuenta', (
    tester,
  ) async {
    final preferencias = PreferenciasFalsas();
    await _abrir(tester, sesion: false, preferencias: preferencias);
    await tester.tap(find.text(Textos.omitir));
    await tester.pumpAndSettle();
    expect(find.byType(RegistroPantalla), findsOneWidget);
    expect(preferencias.bienvenidaVista, isTrue);

    // "Atrás" vuelve a entrar.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(InicioSesionPantalla), findsOneWidget);
  });

  testWidgets('al iniciar sesión se ofrecen los permisos una vez', (
    tester,
  ) async {
    final preferencias = PreferenciasFalsas(bienvenidaVista: true);
    final haySesion = await _abrir(
      tester,
      sesion: false,
      preferencias: preferencias,
    );
    haySesion.value = true;
    await tester.pumpAndSettle();
    expect(find.text(Textos.permisoUbicacionTitulo), findsOneWidget);
  });

  testWidgets('al cerrar sesión vuelve a entrar', (tester) async {
    final haySesion = await _abrir(
      tester,
      sesion: true,
      preferencias: PreferenciasFalsas(
        bienvenidaVista: true,
        permisosOfrecidos: true,
      ),
    );
    haySesion.value = false;
    await tester.pumpAndSettle();
    expect(find.byType(InicioSesionPantalla), findsOneWidget);
  });

  testWidgets('la barra inferior cambia de destino', (tester) async {
    await _abrir(tester, sesion: true);
    await tester.tap(find.text(Textos.navMapa));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(Textos.navMapa),
      ),
      findsOneWidget,
    );
  });
}
