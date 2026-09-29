import 'package:agroclima_jalapa/app.dart';
import 'package:agroclima_jalapa/config/rutas.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:agroclima_jalapa/pantallas/acceso/registro_pantalla.dart';
import 'package:agroclima_jalapa/servicios/cuenta_servicio.dart';

Future<ValueNotifier<bool>> _abrir(
  WidgetTester tester, {
  required bool sesion,
}) async {
  final haySesion = ValueNotifier<bool>(sesion);
  await tester.pumpWidget(
    AgroClimaApp(enrutador: crearEnrutador(haySesion: haySesion)),
  );
  await tester.pumpAndSettle();
  return haySesion;
}

void main() {
  pruebasRegistro();

  group('Guarda de sesión', () {
    testWidgets('sin sesión va a bienvenida, sin barra inferior', (
      tester,
    ) async {
      await _abrir(tester, sesion: false);
      expect(find.text(Textos.navMapa), findsNothing);
      expect(find.text(Textos.enConstruccionTitulo), findsOneWidget);
    });

    testWidgets('con sesión abre Inicio con los 5 destinos', (tester) async {
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

    testWidgets('al cerrar sesión vuelve a bienvenida', (tester) async {
      final haySesion = await _abrir(tester, sesion: true);
      haySesion.value = false;
      await tester.pumpAndSettle();
      expect(find.text(Textos.navMapa), findsNothing);
    });

    testWidgets('al iniciar sesión pasa de bienvenida a Inicio', (
      tester,
    ) async {
      final haySesion = await _abrir(tester, sesion: false);
      haySesion.value = true;
      await tester.pumpAndSettle();
      expect(find.text(Textos.navMapa), findsOneWidget);
    });
  });

  testWidgets('la barra inferior cambia de destino', (tester) async {
    await _abrir(tester, sesion: true);
    await tester.tap(find.text(Textos.navMapa));
    await tester.pumpAndSettle();
    // El título de la barra superior es el del destino elegido.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(Textos.navMapa),
      ),
      findsOneWidget,
    );
  });
}

class _CuentaFalsa extends Mock implements CuentaServicio {}

void pruebasRegistro() {
  testWidgets('desde bienvenida "Crear cuenta" abre el registro', (
    tester,
  ) async {
    final haySesion = ValueNotifier<bool>(false);
    await tester.pumpWidget(
      Provider<CuentaServicio>.value(
        value: _CuentaFalsa(),
        child: AgroClimaApp(enrutador: crearEnrutador(haySesion: haySesion)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(Textos.crearCuenta));
    await tester.pumpAndSettle();
    expect(find.byType(RegistroPantalla), findsOneWidget);
  });
}
