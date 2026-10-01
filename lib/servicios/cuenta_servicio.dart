import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/usuario.dart';
import '../repositorios/auth_repositorio.dart';
import '../repositorios/usuario_repositorio.dart';
import 'notificaciones_servicio.dart';

/// Casos de uso de la cuenta: coordina autenticación, perfil y token de
/// avisos (MOD-01, HU-01 y HU-02).
class CuentaServicio {
  CuentaServicio({
    required this._auth,
    required this._usuarios,
    this._notificaciones,
  });

  final AuthRepositorio _auth;
  final UsuarioRepositorio _usuarios;
  final NotificacionesServicio? _notificaciones;
  StreamSubscription<String>? _vigilanciaToken;

  /// HU-01: crea la cuenta y su perfil con valores por defecto.
  /// [telefono] llega ya con código de país o vacío.
  /// Lanza [ErrorAcceso] si la cuenta no se pudo crear.
  Future<void> registrar({
    required String nombre,
    required String telefono,
    required String correo,
    required String contrasena,
  }) async {
    final uid = await _auth.registrarConCorreo(
      correo: correo,
      contrasena: contrasena,
      nombre: nombre,
    );
    // Si esta escritura falla, el perfil se recrea al entrar (_alEntrar).
    await _intentar(
      () => _usuarios.crearPerfil(
        Usuario(uid: uid, nombre: nombre, correo: correo, telefono: telefono),
      ),
    );
    await _guardarToken(uid);
  }

  /// HU-02: entra con correo y contraseña. Lanza [ErrorAcceso] si falla.
  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final datos = await _auth.iniciarSesionConCorreo(
      correo: correo,
      contrasena: contrasena,
    );
    await _alEntrar(datos);
  }

  /// HU-02 (alterno): entra con Google. La primera vez crea el perfil con el
  /// nombre y correo de Google, sin teléfono (plans/01, flujo 3).
  Future<void> iniciarSesionConGoogle() async {
    final datos = await _auth.iniciarSesionConGoogle();
    await _alEntrar(datos);
  }

  Future<void> recuperarContrasena(String correo) =>
      _auth.recuperarContrasena(correo);

  /// Quita el token de este teléfono, cierra la sesión y borra la copia
  /// local, para que otra persona no vea los datos (MODELO_DATOS §7).
  Future<void> cerrarSesion() async {
    final uid = _auth.uidActual;
    final token = await _notificaciones?.obtenerToken();
    if (uid != null && token != null) {
      await _intentar(() => _usuarios.quitarTokenAvisos(uid, token));
    }
    await _notificaciones?.borrarToken();
    await _auth.cerrarSesion();
    await _intentar(_usuarios.borrarDatosLocales);
  }

  /// Vuelve a guardar el token cuando FCM lo cambia. Se llama una vez al
  /// abrir la app.
  void vigilarTokenDeAvisos() {
    _vigilanciaToken ??= _notificaciones?.tokenRenovado.listen((token) {
      final uid = _auth.uidActual;
      if (uid != null) {
        _intentar(() => _usuarios.agregarTokenAvisos(uid, token));
      }
    });
  }

  /// Si el perfil no existe (primera vez con Google, o el registro no
  /// alcanzó a escribirlo), se crea ahora; luego se guarda el token.
  Future<void> _alEntrar(DatosAcceso datos) async {
    await _intentar(() async {
      final perfil = await _usuarios.obtenerPerfil(datos.uid);
      if (perfil == null) {
        await _usuarios.crearPerfil(
          Usuario(uid: datos.uid, nombre: datos.nombre, correo: datos.correo),
        );
      }
    });
    await _guardarToken(datos.uid);
  }

  Future<void> _guardarToken(String uid) async {
    final token = await _notificaciones?.obtenerToken();
    if (token != null) {
      await _intentar(() => _usuarios.agregarTokenAvisos(uid, token));
    }
  }

  /// El perfil y el token no deben impedir entrar: si fallan, se registra
  /// y se reintenta en el próximo acceso.
  Future<void> _intentar(Future<void> Function() accion) async {
    try {
      await accion();
    } catch (error) {
      debugPrint('Paso secundario de la cuenta falló: $error');
    }
  }
}
