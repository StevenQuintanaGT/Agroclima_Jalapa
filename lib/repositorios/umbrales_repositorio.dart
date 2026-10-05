import '../modelos/umbral.dart';

/// Contrato del catálogo de umbrales (CO-11), solo lectura (RNF-19).
/// Implementación: `FirestoreUmbralesRepositorio`.
abstract class UmbralesRepositorio {
  /// Umbrales vigentes; con la copia del teléfono si no hay señal.
  Future<List<Umbral>> vigentes();
}
