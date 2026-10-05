import '../modelos/alerta.dart';

/// Contrato de las alertas del productor (CO-14). Solo lectura, salvo
/// `leida` y `atendida` (Tabla 75). Implementación: `FirestoreAlertasRepositorio`.
abstract class AlertasRepositorio {
  /// Alertas del usuario en vivo, de la más nueva a la más vieja
  /// (índice 1: usuarioId + fechaGeneracion). Sin señal, la copia local.
  Stream<List<Alerta>> delUsuario(String usuarioId);

  /// Una alerta en vivo; `null` si no existe o no se entiende.
  Stream<Alerta?> observar(String alertaId);

  /// Abrió el detalle. Funciona sin señal (se sube al volver).
  Future<void> marcarLeida(String alertaId);

  /// "Ya tomé medidas".
  Future<void> marcarAtendida(String alertaId);
}
