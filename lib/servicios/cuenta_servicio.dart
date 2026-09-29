import '../modelos/usuario.dart';
import '../repositorios/auth_repositorio.dart';
import '../repositorios/usuario_repositorio.dart';

/// Casos de uso de la cuenta: coordina autenticación y perfil (MOD-01).
class CuentaServicio {
  CuentaServicio({required this._auth, required this._usuarios});

  final AuthRepositorio _auth;
  final UsuarioRepositorio _usuarios;

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
    // Si esta escritura fallara, el perfil se vuelve a crear al entrar (HU-02).
    await _usuarios.crearPerfil(
      Usuario(uid: uid, nombre: nombre, correo: correo, telefono: telefono),
    );
  }
}
