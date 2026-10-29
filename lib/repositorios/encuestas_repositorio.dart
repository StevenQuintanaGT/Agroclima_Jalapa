import '../modelos/encuesta.dart';

/// Contrato de la encuesta de satisfacción (`encuestas/{uid}`, D-58).
/// Implementación: `FirestoreEncuestasRepositorio`.
abstract class EncuestasRepositorio {
  /// La encuesta que ya envió el usuario, o `null` si no ha respondido.
  /// Sin señal, la copia del teléfono.
  Future<Encuesta?> obtener(String uid);

  /// Guarda (o reemplaza) la encuesta con la hora del servidor. Sin señal
  /// queda en el teléfono y se sube sola.
  Future<void> guardar(Encuesta encuesta);
}
