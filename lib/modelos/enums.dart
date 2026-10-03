/// Enumeraciones del dominio. `valor` es exactamente lo que se guarda en
/// Firestore (docs/MODELO_DATOS.md §2); las etiquetas viven en textos.dart.
///
/// Los 7 municipios del departamento de Jalapa (MODELO_DATOS §2).
enum Municipio {
  jalapa('jalapa'),
  sanPedroPinula('sanPedroPinula'),
  sanLuisJilotepeque('sanLuisJilotepeque'),
  sanManuelChaparron('sanManuelChaparron'),
  sanCarlosAlzatate('sanCarlosAlzatate'),
  monjas('monjas'),
  mataquescuintla('mataquescuintla');

  const Municipio(this.valor);

  final String valor;

  static Municipio? desdeValor(String? valor) {
    for (final municipio in values) {
      if (municipio.valor == valor) return municipio;
    }
    return null;
  }
}

/// Cultivo y Etapa se agregan con HU-05.
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
