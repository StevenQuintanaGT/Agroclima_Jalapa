/// Enumeraciones del dominio. `valor` es exactamente lo que se guarda en
/// Firestore (docs/MODELO_DATOS.md §2); las etiquetas viven en textos.dart.
///
/// Municipio, Cultivo, Etapa y TipoRiesgo se agregan con sus historias.
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
