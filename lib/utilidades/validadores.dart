import '../config/constantes.dart';
import '../config/textos.dart';

/// Validaciones de formularios (Tabla 48). Cada una devuelve el mensaje de
/// error en lenguaje llano, o `null` si el valor está bien.
class Validadores {
  Validadores._();

  static final RegExp _correo = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? nombre(String valor) =>
      valor.trim().isEmpty ? Textos.errorNombreVacio : null;

  /// VA-04.
  static String? correo(String valor) =>
      _correo.hasMatch(valor.trim()) ? null : Textos.errorCorreo;

  /// VA-05: al menos 8 caracteres (§5.6.1).
  static String? contrasena(String valor) =>
      valor.length >= Constantes.largoMinimoContrasena
      ? null
      : Textos.errorContrasenaCorta;

  static String? repetirContrasena(String valor, String contrasena) =>
      valor == contrasena ? null : Textos.errorContrasenasDistintas;

  /// Teléfono opcional: vacío, o los 8 números de Guatemala (se aceptan
  /// espacios y guiones).
  static String? telefono(String valor) {
    final digitos = soloDigitos(valor);
    if (digitos.isEmpty || digitos.length == 8) return null;
    return Textos.errorTelefono;
  }

  /// Teléfono como se guarda: `+502` + 8 números, o vacío.
  static String telefonoConCodigo(String valor) {
    final digitos = soloDigitos(valor);
    return digitos.isEmpty ? '' : '${Textos.prefijoGuatemala}$digitos';
  }

  static String soloDigitos(String valor) =>
      valor.replaceAll(RegExp(r'\D'), '');
}
