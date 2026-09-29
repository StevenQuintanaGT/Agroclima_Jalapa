import '../modelos/usuario.dart';

/// Contrato del perfil del productor y sus preferencias de avisos.
/// Implementación: `FirestoreUsuarioRepositorio`.
abstract class UsuarioRepositorio {
  /// Crea `usuarios/{uid}` y las 6 preferencias por defecto (Tablas 64 y 65)
  /// en una sola escritura.
  Future<void> crearPerfil(Usuario usuario);

  /// Perfil del usuario, o `null` si todavía no existe.
  Future<Usuario?> obtenerPerfil(String uid);
}
