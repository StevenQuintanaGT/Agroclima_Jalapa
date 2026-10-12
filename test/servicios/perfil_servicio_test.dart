import 'dart:async';

import 'package:agroclima_jalapa/modelos/usuario.dart';
import 'package:agroclima_jalapa/repositorios/auth_repositorio.dart';
import 'package:agroclima_jalapa/repositorios/usuario_repositorio.dart';
import 'package:agroclima_jalapa/servicios/perfil_servicio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AuthFalso extends Mock implements AuthRepositorio {}

class _UsuariosFalso extends Mock implements UsuarioRepositorio {}

void main() {
  late _AuthFalso auth;
  late _UsuariosFalso usuarios;
  late StreamController<String?> sesion;
  late StreamController<Usuario?> perfilAna;

  setUp(() {
    auth = _AuthFalso();
    usuarios = _UsuariosFalso();
    sesion = StreamController<String?>();
    perfilAna = StreamController<Usuario?>();
    when(() => auth.cambiosDeSesion).thenAnswer((_) => sesion.stream);
    when(() => usuarios.observarPerfil('ana'))
        .thenAnswer((_) => perfilAna.stream);
    when(
      () => usuarios.guardarAjustes(
        any(),
        unidadTemperatura: any(named: 'unidadTemperatura'),
        unidadArea: any(named: 'unidadArea'),
        temaOscuro: any(named: 'temaOscuro'),
        ahorroDatos: any(named: 'ahorroDatos'),
      ),
    ).thenAnswer((_) async {});
  });

  test('sin sesión: tema claro, °C y manzanas', () {
    when(() => auth.uidActual).thenReturn(null);
    final servicio = PerfilServicio(auth: auth, usuarios: usuarios);
    expect(servicio.usuario, isNull);
    expect(servicio.temaOscuro, isFalse);
    expect(servicio.fahrenheit, isFalse);
    expect(servicio.hectareas, isFalse);
    expect(servicio.ahorroDatos, isFalse);
    servicio.dispose();
  });

  test('sigue el perfil de quien entra y lo suelta al salir', () async {
    when(() => auth.uidActual).thenReturn('ana');
    final servicio = PerfilServicio(auth: auth, usuarios: usuarios);
    var avisos = 0;
    servicio.addListener(() => avisos++);
    perfilAna.add(
      const Usuario(
        uid: 'ana',
        nombre: 'Ana',
        correo: 'a@c.com',
        unidadTemperatura: 'F',
        unidadArea: 'hectarea',
        temaOscuro: true,
        ahorroDatos: true,
      ),
    );
    await pumpEventQueue();
    expect(servicio.fahrenheit, isTrue);
    expect(servicio.hectareas, isTrue);
    expect(servicio.temaOscuro, isTrue);
    expect(servicio.ahorroDatos, isTrue);
    expect(avisos, 1);

    sesion.add(null);
    await pumpEventQueue();
    expect(servicio.usuario, isNull);
    expect(servicio.temaOscuro, isFalse);
    servicio.dispose();
  });

  test('cada interruptor guarda solo su campo', () async {
    when(() => auth.uidActual).thenReturn('ana');
    final servicio = PerfilServicio(auth: auth, usuarios: usuarios);
    await servicio.cambiarFahrenheit(true);
    verify(() => usuarios.guardarAjustes('ana', unidadTemperatura: 'F'));
    await servicio.cambiarHectareas(false);
    verify(() => usuarios.guardarAjustes('ana', unidadArea: 'manzana'));
    await servicio.cambiarTemaOscuro(true);
    verify(() => usuarios.guardarAjustes('ana', temaOscuro: true));
    await servicio.cambiarAhorroDatos(true);
    verify(() => usuarios.guardarAjustes('ana', ahorroDatos: true));
    servicio.dispose();
  });
}
