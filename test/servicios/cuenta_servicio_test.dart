import 'dart:async';

import 'package:agroclima_jalapa/modelos/usuario.dart';
import 'package:agroclima_jalapa/repositorios/auth_repositorio.dart';
import 'package:agroclima_jalapa/repositorios/usuario_repositorio.dart';
import 'package:agroclima_jalapa/servicios/cuenta_servicio.dart';
import 'package:agroclima_jalapa/servicios/estado_sesion.dart';
import 'package:agroclima_jalapa/servicios/notificaciones_servicio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AuthFalso extends Mock implements AuthRepositorio {}

class _UsuariosFalso extends Mock implements UsuarioRepositorio {}

void main() {
  group("HU-02", pruebasHu02);

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

class _NotificacionesFalsas extends Mock implements NotificacionesServicio {}

void pruebasHu02() {
  late _AuthFalso auth;
  late _UsuariosFalso usuarios;
  late _NotificacionesFalsas notificaciones;
  late CuentaServicio servicio;

  const datos = DatosAcceso(uid: 'u1', nombre: 'Ana', correo: 'ana@c.com');

  setUp(() {
    auth = _AuthFalso();
    usuarios = _UsuariosFalso();
    notificaciones = _NotificacionesFalsas();
    servicio = CuentaServicio(
      auth: auth,
      usuarios: usuarios,
      notificaciones: notificaciones,
    );
    when(() => notificaciones.obtenerToken()).thenAnswer((_) async => 'tok-1');
    when(() => notificaciones.borrarToken()).thenAnswer((_) async {});
    when(() => usuarios.agregarTokenAvisos(any(), any()))
        .thenAnswer((_) async {});
    when(() => usuarios.quitarTokenAvisos(any(), any()))
        .thenAnswer((_) async {});
    when(() => usuarios.crearPerfil(any())).thenAnswer((_) async {});
    when(() => usuarios.borrarDatosLocales()).thenAnswer((_) async {});
    when(
      () => auth.iniciarSesionConCorreo(
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
      ),
    ).thenAnswer((_) async => datos);
  });

  test('al entrar con perfil existente solo guarda el token', () async {
    when(() => usuarios.obtenerPerfil('u1')).thenAnswer(
      (_) async => const Usuario(uid: 'u1', nombre: 'Ana', correo: 'ana@c.com'),
    );
    await servicio.iniciarSesion(correo: 'ana@c.com', contrasena: 'x');
    verifyNever(() => usuarios.crearPerfil(any()));
    verify(() => usuarios.agregarTokenAvisos('u1', 'tok-1')).called(1);
  });

  test('si falta el perfil (p. ej. Google la primera vez) lo crea', () async {
    when(() => usuarios.obtenerPerfil('u1')).thenAnswer((_) async => null);
    when(() => auth.iniciarSesionConGoogle()).thenAnswer((_) async => datos);
    await servicio.iniciarSesionConGoogle();
    final perfil =
        verify(() => usuarios.crearPerfil(captureAny())).captured.single
            as Usuario;
    expect(perfil.nombre, 'Ana');
    expect(perfil.telefono, '');
  });

  test('si el perfil o el token fallan, igual entra', () async {
    when(() => usuarios.obtenerPerfil('u1')).thenThrow(Exception('sin red'));
    when(() => usuarios.agregarTokenAvisos(any(), any()))
        .thenThrow(Exception('sin red'));
    await expectLater(
      servicio.iniciarSesion(correo: 'ana@c.com', contrasena: 'x'),
      completes,
    );
  });

  test('cerrar sesión: quita el token, sale y borra la copia local', () async {
    when(() => auth.uidActual).thenReturn('u1');
    when(() => auth.cerrarSesion()).thenAnswer((_) async {});
    await servicio.cerrarSesion();
    verifyInOrder([
      () => usuarios.quitarTokenAvisos('u1', 'tok-1'),
      () => notificaciones.borrarToken(),
      () => auth.cerrarSesion(),
      () => usuarios.borrarDatosLocales(),
    ]);
  });

  test('recuperar contraseña delega en la autenticación', () async {
    when(() => auth.recuperarContrasena(any())).thenAnswer((_) async {});
    await servicio.recuperarContrasena('ana@c.com');
    verify(() => auth.recuperarContrasena('ana@c.com')).called(1);
  });
}
