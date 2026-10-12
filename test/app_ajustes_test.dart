import 'dart:async';
import 'dart:io';

import 'package:agroclima_jalapa/app.dart';
import 'package:agroclima_jalapa/config/constantes.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/usuario.dart';
import 'package:agroclima_jalapa/repositorios/auth_repositorio.dart';
import 'package:agroclima_jalapa/repositorios/usuario_repositorio.dart';
import 'package:agroclima_jalapa/servicios/perfil_servicio.dart';
import 'package:agroclima_jalapa/utilidades/unidades.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _AuthFalso extends Mock implements AuthRepositorio {}

class _UsuariosFalso extends Mock implements UsuarioRepositorio {}

/// Ajustes (29) aplicados en toda la app al instante (D-55).
void main() {
  tearDown(() {
    Unidades.enFahrenheit = false;
    Unidades.enHectareas = false;
  });

  testWidgets('°F, hectáreas y pantalla oscura se ven sin reabrir', (
    tester,
  ) async {
    final auth = _AuthFalso();
    final usuarios = _UsuariosFalso();
    final perfilEnVivo = StreamController<Usuario?>();
    when(() => auth.uidActual).thenReturn('ana');
    when(() => auth.cambiosDeSesion).thenAnswer((_) => const Stream.empty());
    when(() => usuarios.observarPerfil('ana'))
        .thenAnswer((_) => perfilEnVivo.stream);
    final perfil = PerfilServicio(auth: auth, usuarios: usuarios);
    addTearDown(perfil.dispose);
    final enrutador = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Column(
              children: [
                Text(Textos.grados(20)),
                Text(Textos.area(2, 'manzana')),
                Text(Theme.of(context).brightness.name),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(enrutador.dispose);

    await tester.pumpWidget(AgroClimaApp(enrutador: enrutador, perfil: perfil));
    await tester.pumpAndSettle();
    expect(find.text('20°'), findsOneWidget);
    expect(find.text('2 manzanas'), findsOneWidget);
    expect(find.text('light'), findsOneWidget);

    perfilEnVivo.add(
      const Usuario(
        uid: 'ana',
        nombre: 'Ana',
        correo: 'a@c.com',
        unidadTemperatura: 'F',
        unidadArea: 'hectarea',
        temaOscuro: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('68°'), findsOneWidget);
    expect(find.text('1.4 ha'), findsOneWidget);
    expect(find.text('dark'), findsOneWidget);
  });

  test('la versión de "Acerca de" es la del pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([\d.]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(Constantes.versionApp, version);
  });
}
