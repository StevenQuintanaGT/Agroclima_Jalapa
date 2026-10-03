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

/// Cultivos con umbrales propios (DECISIONES D-01). Sin cultivo = solo
/// alertas generales (RN-05); en Firestore se guarda "".
enum Cultivo {
  maiz('maiz'),
  frijol('frijol'),
  cafe('cafe'),
  hortalizas('hortalizas');

  const Cultivo(this.valor);

  final String valor;

  static Cultivo? desdeValor(String? valor) {
    for (final cultivo in values) {
      if (cultivo.valor == valor) return cultivo;
    }
    return null;
  }
}

/// Etapas del cultivo (DECISIONES D-02). Sin etapa = "" en Firestore.
enum Etapa {
  siembra('siembra'),
  desarrolloVegetativo('desarrolloVegetativo'),
  floracion('floracion'),
  llenado('llenado'),
  cosecha('cosecha');

  const Etapa(this.valor);

  final String valor;

  static Etapa? desdeValor(String? valor) {
    for (final etapa in values) {
      if (etapa.valor == valor) return etapa;
    }
    return null;
  }
}

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
