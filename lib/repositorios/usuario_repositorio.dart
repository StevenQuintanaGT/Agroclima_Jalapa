import '../modelos/usuario.dart';

/// Contrato del perfil del productor y sus preferencias de avisos.
/// Implementación: `FirestoreUsuarioRepositorio`.
abstract class UsuarioRepositorio {
  /// Crea `usuarios/{uid}` y las 6 preferencias por defecto (Tablas 64 y 65)
  /// en una sola escritura.
  Future<void> crearPerfil(Usuario usuario);

  /// Perfil del usuario, o `null` si todavía no existe.
  Future<Usuario?> obtenerPerfil(String uid);

  /// Agrega el token de avisos de este teléfono (Tabla 76: un token por
  /// teléfono con sesión activa).
  Future<void> agregarTokenAvisos(String uid, String token);

  /// Quita el token al cerrar sesión: este teléfono deja de recibir avisos.
  Future<void> quitarTokenAvisos(String uid, String token);

  /// Borra la copia local de los datos al cerrar sesión (MODELO_DATOS §7).
  Future<void> borrarDatosLocales();
}
