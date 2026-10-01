/// Error de acceso con un código estable (los de Firebase Auth, p. ej.
/// `email-already-in-use`). La pantalla lo traduce con `utilidades/errores.dart`.
class ErrorAcceso implements Exception {
  const ErrorAcceso(this.codigo);

  /// El productor cerró la ventana de Google: no es un error que mostrar.
  static const String cancelado = 'cancelado';

  final String codigo;

  @override
  String toString() => 'ErrorAcceso($codigo)';
}

/// Lo que se sabe del usuario al iniciar sesión.
class DatosAcceso {
  const DatosAcceso({
    required this.uid,
    required this.nombre,
    required this.correo,
  });

  final String uid;
  final String nombre;
  final String correo;
}

/// Contrato de autenticación (CO-02). La app no conoce Firebase: solo este
/// contrato (RNF-20). Implementación: `FirebaseAuthRepositorio`.
abstract class AuthRepositorio {
  /// Uid del usuario con sesión, o `null`. Firebase la restaura sola al abrir
  /// la app, así que la sesión persiste (HU-02).
  String? get uidActual;

  /// Emite el uid cada vez que se inicia o cierra sesión (`null` sin sesión).
  Stream<String?> get cambiosDeSesion;

  /// Crea la cuenta con correo y contraseña y deja la sesión iniciada.
  /// Devuelve el uid. Lanza [ErrorAcceso] si falla.
  Future<String> registrarConCorreo({
    required String correo,
    required String contrasena,
    required String nombre,
  });

  /// Lanza [ErrorAcceso] si las credenciales no coinciden o no hay señal.
  Future<DatosAcceso> iniciarSesionConCorreo({
    required String correo,
    required String contrasena,
  });

  /// Abre la ventana de cuentas de Google. Lanza [ErrorAcceso] con
  /// [ErrorAcceso.cancelado] si el productor la cierra.
  Future<DatosAcceso> iniciarSesionConGoogle();

  /// Manda el enlace para poner una contraseña nueva.
  Future<void> recuperarContrasena(String correo);

  Future<void> cerrarSesion();
}
