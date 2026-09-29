import 'dart:async';

import 'package:agroclima_jalapa/modelos/usuario.dart';
import 'package:agroclima_jalapa/repositorios/auth_repositorio.dart';
import 'package:agroclima_jalapa/repositorios/usuario_repositorio.dart';
import 'package:agroclima_jalapa/servicios/cuenta_servicio.dart';
import 'package:agroclima_jalapa/servicios/estado_sesion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AuthFalso extends Mock implements AuthRepositorio {}

class _UsuariosFalso extends Mock implements UsuarioRepositorio {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Usuario(uid: '', nombre: '', correo: ''));
  });

  late _AuthFalso auth;
  late _UsuariosFalso usuarios;
  late CuentaServicio servicio;

  setUp(() {
    auth = _AuthFalso();
    usuarios = _UsuariosFalso();
    servicio = CuentaServicio(auth: auth, usuarios: usuarios);
  });

  test('registrar crea la cuenta y luego el perfil con ese uid', () async {
    when(
      () => auth.registrarConCorreo(
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
        nombre: any(named: 'nombre'),
      ),
    ).thenAnswer((_) async => 'uid-123');
    when(() => usuarios.crearPerfil(any())).thenAnswer((_) async {});

    await servicio.registrar(
      nombre: 'Juan López',
      telefono: '+50255123456',
      correo: 'juan@correo.com',
      contrasena: 'secreta123',
    );

    final perfil =
        verify(() => usuarios.crearPerfil(captureAny())).captured.single
            as Usuario;
    expect(perfil.uid, 'uid-123');
    expect(perfil.nombre, 'Juan López');
    expect(perfil.telefono, '+50255123456');
    expect(perfil.correo, 'juan@correo.com');
  });

  test('si la cuenta no se crea, no se escribe perfil', () async {
    when(
      () => auth.registrarConCorreo(
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
        nombre: any(named: 'nombre'),
      ),
    ).thenThrow(const ErrorAcceso('email-already-in-use'));

    await expectLater(
      servicio.registrar(
        nombre: 'Ana',
        telefono: '',
        correo: 'ana@correo.com',
        contrasena: 'secreta123',
      ),
      throwsA(isA<ErrorAcceso>()),
    );
    verifyNever(() => usuarios.crearPerfil(any()));
  });

  test('EstadoSesion sigue los cambios de sesión', () async {
    final cambios = StreamController<String?>();
    when(() => auth.uidActual).thenReturn(null);
    when(() => auth.cambiosDeSesion).thenAnswer((_) => cambios.stream);

    final estado = EstadoSesion(auth);
    expect(estado.value, isFalse);

    cambios.add('uid-1');
    await Future<void>.delayed(Duration.zero);
    expect(estado.value, isTrue);

    cambios.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(estado.value, isFalse);

    estado.dispose();
    await cambios.close();
  });

  test('EstadoSesion arranca con la sesión restaurada (HU-02)', () {
    when(() => auth.uidActual).thenReturn('uid-guardado');
    when(() => auth.cambiosDeSesion).thenAnswer((_) => const Stream.empty());
    final estado = EstadoSesion(auth);
    expect(estado.value, isTrue);
    estado.dispose();
  });
}
