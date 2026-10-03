import 'error_clima.dart';

/// Dato del clima con su vigencia (política "caché primero", RNF-08): lo que
/// se muestra, de cuándo es, si sigue vigente y, si no se pudo actualizar,
/// por qué.
class Resultado<T> {
  const Resultado({
    required this.dato,
    required this.fecha,
    required this.vigente,
    this.error,
  });

  /// Sin dato guardado y sin poder traerlo.
  const Resultado.vacio(MotivoErrorClima this.error)
    : dato = null,
      fecha = null,
      vigente = false;

  final T? dato;

  /// Momento del dato (UTC).
  final DateTime? fecha;

  /// `false` si pasó su vigencia (D-08) y no se pudo actualizar.
  final bool vigente;

  /// Por qué no se actualizó; `null` si todo salió bien.
  final MotivoErrorClima? error;

  bool get hayDato => dato != null;
}
