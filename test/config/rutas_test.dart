import 'package:agroclima_jalapa/config/rutas.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoyo/preferencias_falsas.dart';

void main() {
  String? destino(
    String ubicacion, {
    required bool sesion,
    bool bienvenidaVista = false,
    bool permisosOfrecidos = false,
  }) => destinoSegunSesion(
    ubicacion: ubicacion,
    haySesion: sesion,
    preferencias: PreferenciasFalsas(
      bienvenidaVista: bienvenidaVista,
      permisosOfrecidos: permisosOfrecidos,
    ),
  );

  test('el splash siempre se muestra', () {
    expect(destino(Rutas.splash, sesion: false), isNull);
    expect(destino(Rutas.splash, sesion: true), isNull);
  });

  group('sin sesión', () {
    test('primera vez → bienvenida', () {
      expect(destino(Rutas.inicio, sesion: false), Rutas.bienvenida);
    });

    test('ya vio la bienvenida → entrar', () {
      expect(
        destino(Rutas.inicio, sesion: false, bienvenidaVista: true),
        Rutas.entrar,
      );
    });

    test('las pantallas de acceso se pueden abrir', () {
      for (final ruta in [
        Rutas.bienvenida,
        Rutas.entrar,
        Rutas.registro,
        Rutas.recuperar,
      ]) {
        expect(destino(ruta, sesion: false), isNull, reason: ruta);
      }
    });

    test('no puede ver permisos ni el contenedor', () {
      expect(destino(Rutas.permisoUbicacion, sesion: false), Rutas.bienvenida);
      expect(destino(Rutas.alertas, sesion: false), Rutas.bienvenida);
    });
  });

  group('con sesión (HU-02: no se vuelve a pedir acceso)', () {
    test('recién entrado: primero los permisos', () {
      expect(destino(Rutas.entrar, sesion: true), Rutas.permisoUbicacion);
      expect(destino(Rutas.registro, sesion: true), Rutas.permisoUbicacion);
    });

    test('permisos ya ofrecidos → Inicio', () {
      expect(
        destino(Rutas.entrar, sesion: true, permisosOfrecidos: true),
        Rutas.inicio,
      );
      expect(
        destino(Rutas.bienvenida, sesion: true, permisosOfrecidos: true),
        Rutas.inicio,
      );
    });

    test('dentro de la app no hay redirección', () {
      expect(destino(Rutas.inicio, sesion: true), isNull);
      expect(destino(Rutas.permisoAvisos, sesion: true), isNull);
      expect(destino(Rutas.perfil, sesion: true), isNull);
    });
  });
}
