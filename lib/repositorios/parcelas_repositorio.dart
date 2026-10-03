import '../modelos/parcela.dart';

/// Resultado de guardar: el id asignado y si quedó pendiente de subir.
class ParcelaGuardada {
  const ParcelaGuardada({required this.parcelaId, required this.pendiente});

  final String parcelaId;

  /// `true` si no hubo señal: se guardó en el teléfono y se enviará solo.
  final bool pendiente;
}

/// Contrato de parcelas (CO-06). Implementación: `FirestoreParcelasRepositorio`.
abstract class ParcelasRepositorio {
  /// Crea la parcela. Funciona sin señal (RNF-16).
  Future<ParcelaGuardada> crear(Parcela parcela);

  /// Parcelas del productor, en vivo (también las guardadas sin señal).
  Stream<List<Parcela>> listar(String usuarioId);

  /// Una parcela en vivo; `null` si no existe o se borró.
  Stream<Parcela?> observar(String parcelaId);

  /// Nombres de las parcelas del productor, para no repetirlos (VA-02).
  Future<List<String>> nombres(String usuarioId);

  /// Guarda los cambios de una parcela existente (HU-06). Funciona sin señal.
  /// Devuelve `true` si quedó pendiente de subir.
  Future<bool> actualizar(Parcela parcela);

  /// Borra el documento de la parcela (HU-06). Su historial y sus alertas los
  /// borra el ciclo automático (D-37). Devuelve `true` si quedó pendiente.
  Future<bool> eliminar(String parcelaId);
}
