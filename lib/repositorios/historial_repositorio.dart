import '../modelos/registro_dia.dart';

/// Contrato del historial de condiciones (CO-16). Solo lee lo ya guardado:
/// no llama a OpenWeather. Implementación: `FirestoreHistorialRepositorio`.
abstract class HistorialRepositorio {
  /// Los últimos [limite] días guardados de la parcela, del más nuevo al más
  /// viejo (por el campo `fecha` `yyyyMMdd`, sin índice extra). En vivo y con la
  /// copia del teléfono si no hay señal.
  Stream<List<RegistroDia>> dias(String parcelaId, {required int limite});

  /// Días guardados entre [desde] y [hasta] (`yyyyMMdd`, ambos incluidos),
  /// del más viejo al más nuevo (Reportes, HU-16).
  Stream<List<RegistroDia>> rango(
    String parcelaId, {
    required String desde,
    required String hasta,
  });
}
