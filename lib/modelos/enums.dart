/// Enumeraciones del dominio. `valor` es exactamente lo que se guarda en
/// Firestore (docs/MODELO_DATOS.md §2); las etiquetas viven en textos.dart.
///
/// Municipio, Cultivo y Etapa se agregan con sus historias.
enum TipoRiesgo {
  lluviaIntensa('lluviaIntensa'),
  vientoFuerte('vientoFuerte'),
  sequia('sequia'),
  temperaturaBaja('temperaturaBaja'),
  temperaturaAlta('temperaturaAlta'),
  humedadAlta('humedadAlta');

  const TipoRiesgo(this.valor);

  final String valor;

  static TipoRiesgo? desdeValor(String? valor) {
    for (final tipo in values) {
      if (tipo.valor == valor) return tipo;
    }
    return null;
  }
}

enum NivelSeveridad {
  informativa('informativa'),
  preventiva('preventiva'),
  critica('critica');

  const NivelSeveridad(this.valor);

  final String valor;

  static NivelSeveridad? desdeValor(String? valor) {
    for (final nivel in values) {
      if (nivel.valor == valor) return nivel;
    }
    return null;
  }
}
