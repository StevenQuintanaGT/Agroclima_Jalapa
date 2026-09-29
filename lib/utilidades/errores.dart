import '../config/textos.dart';

/// Traduce códigos de error a texto llano. Nunca se muestra el código al
/// productor (CLAUDE.md §10).
class Errores {
  Errores._();

  static String deAcceso(String codigo) => switch (codigo) {
    'email-already-in-use' => Textos.errorCorreoEnUso,
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => Textos.errorCredenciales,
    'invalid-email' => Textos.errorCorreo,
    'weak-password' => Textos.errorContrasenaDebil,
    'network-request-failed' => Textos.errorSinSenal,
    'too-many-requests' => Textos.errorMuchosIntentos,
    _ => Textos.errorGenerico,
  };
}
