/// Respuestas de la encuesta de satisfacción ("Su opinión", D-58). Cada
/// pregunta de opción guarda uno de los valores de [opciones]; las etiquetas
/// en pantalla viven en `Textos.opcionEncuesta`. `null` = sin responder.
class RespuestasEncuesta {
  const RespuestasEncuesta({
    this.p1,
    this.p2,
    this.p3,
    this.p4,
    this.p5,
    this.p6,
    this.p7,
    this.p8,
    this.detalleAviso,
    this.detalleAccion,
    this.detalleDanio,
    this.consentimiento,
  });

  /// Valores guardados de cada pregunta de opción (MODELO_DATOS §3).
  static const Map<String, List<String>> opciones = {
    'p1': ['facil', 'masOMenos', 'dificil'],
    'p2': ['todo', 'mayoria', 'poco'],
    'p3': ['si', 'no'],
    'p4': ['mucho', 'algo', 'poco'],
    'p5': ['si', 'no'],
    'p6': ['si', 'sinDanio', 'no'],
    'p7': ['si', 'talVez', 'no'],
  };

  /// Las que hay que responder para poder enviar (además del consentimiento).
  static const List<String> obligatorias = ['p1', 'p2', 'p4', 'p5', 'p6', 'p7'];

  final String? p1;
  final String? p2;
  final String? p3;
  final String? p4;
  final String? p5;
  final String? p6;
  final String? p7;

  /// Texto libre: qué le cambiaría o agregaría.
  final String? p8;

  /// Solo si p3 = `si`: de qué fue el aviso.
  final String? detalleAviso;

  /// Solo si p5 = `si`: qué hizo.
  final String? detalleAccion;

  /// Solo si p6 = `si`: qué daño evitó o redujo.
  final String? detalleDanio;

  /// Permiso para usar nombre, respuestas y foto en el trabajo de graduación.
  final bool? consentimiento;

  /// Valor elegido de una pregunta de opción (`p1`…`p7`).
  String? elegido(String pregunta) => switch (pregunta) {
    'p1' => p1,
    'p2' => p2,
    'p3' => p3,
    'p4' => p4,
    'p5' => p5,
    'p6' => p6,
    'p7' => p7,
    _ => null,
  };

  bool get completa =>
      obligatorias.every((p) => elegido(p) != null) && consentimiento != null;

  /// Copia con [valor] elegido en [pregunta] (`p1`…`p7`).
  RespuestasEncuesta elegir(String pregunta, String valor) =>
      RespuestasEncuesta(
        p1: pregunta == 'p1' ? valor : p1,
        p2: pregunta == 'p2' ? valor : p2,
        p3: pregunta == 'p3' ? valor : p3,
        p4: pregunta == 'p4' ? valor : p4,
        p5: pregunta == 'p5' ? valor : p5,
        p6: pregunta == 'p6' ? valor : p6,
        p7: pregunta == 'p7' ? valor : p7,
        p8: p8,
        detalleAviso: detalleAviso,
        detalleAccion: detalleAccion,
        detalleDanio: detalleDanio,
        consentimiento: consentimiento,
      );

  RespuestasEncuesta copyWith({
    String? p8,
    String? detalleAviso,
    String? detalleAccion,
    String? detalleDanio,
    bool? consentimiento,
  }) => RespuestasEncuesta(
    p1: p1,
    p2: p2,
    p3: p3,
    p4: p4,
    p5: p5,
    p6: p6,
    p7: p7,
    p8: p8 ?? this.p8,
    detalleAviso: detalleAviso ?? this.detalleAviso,
    detalleAccion: detalleAccion ?? this.detalleAccion,
    detalleDanio: detalleDanio ?? this.detalleDanio,
    consentimiento: consentimiento ?? this.consentimiento,
  );

  /// Lo que se guarda: textos sin espacios de más y vacíos como `null`; el
  /// detalle de una pregunta solo queda si se respondió "Sí".
  RespuestasEncuesta limpias() => RespuestasEncuesta(
    p1: p1,
    p2: p2,
    p3: p3,
    p4: p4,
    p5: p5,
    p6: p6,
    p7: p7,
    p8: _texto(p8),
    detalleAviso: p3 == 'si' ? _texto(detalleAviso) : null,
    detalleAccion: p5 == 'si' ? _texto(detalleAccion) : null,
    detalleDanio: p6 == 'si' ? _texto(detalleDanio) : null,
    consentimiento: consentimiento,
  );

  static String? _texto(String? valor) {
    final limpio = valor?.trim() ?? '';
    return limpio.isEmpty ? null : limpio;
  }

  Map<String, dynamic> toMap() => {
    'p1': ?p1,
    'p2': ?p2,
    'p3': ?p3,
    'p4': ?p4,
    'p5': ?p5,
    'p6': ?p6,
    'p7': ?p7,
    'p8': ?p8,
    'detalleAviso': ?detalleAviso,
    'detalleAccion': ?detalleAccion,
    'detalleDanio': ?detalleDanio,
    'consentimiento': ?consentimiento,
  };

  /// Un valor que ya no está entre las opciones se toma como sin responder.
  factory RespuestasEncuesta.fromMap(Map<String, dynamic> mapa) {
    String? opcion(String pregunta) {
      final valor = mapa[pregunta];
      return opciones[pregunta]!.contains(valor) ? valor as String : null;
    }

    String? texto(String campo) => mapa[campo] is String ? mapa[campo] : null;
    return RespuestasEncuesta(
      p1: opcion('p1'),
      p2: opcion('p2'),
      p3: opcion('p3'),
      p4: opcion('p4'),
      p5: opcion('p5'),
      p6: opcion('p6'),
      p7: opcion('p7'),
      p8: texto('p8'),
      detalleAviso: texto('detalleAviso'),
      detalleAccion: texto('detalleAccion'),
      detalleDanio: texto('detalleDanio'),
      consentimiento: mapa['consentimiento'] is bool
          ? mapa['consentimiento'] as bool
          : null,
    );
  }
}
