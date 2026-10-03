/// Clima de este momento en un punto, como lo entrega el proveedor ya
/// traducido al dominio (Current Weather 2.5). Unidades métricas: °C, %,
/// mm y km/h. Se guarda en `condiciones` como [Condicion].
class ClimaActual {
  const ClimaActual({
    required this.fechaHora,
    required this.temperatura,
    required this.sensacionTermica,
    required this.humedadRelativa,
    required this.lluviaUltimaHora,
    required this.velocidadViento,
    required this.codigoClima,
    this.direccionViento,
    this.descripcion = '',
    this.salidaSol,
    this.puestaSol,
  });

  /// Momento de la observación (UTC).
  final DateTime fechaHora;
  final double temperatura;
  final double sensacionTermica;
  final double humedadRelativa;

  /// mm caídos en la última hora (0 si no llovió).
  final double lluviaUltimaHora;
  final double velocidadViento;

  /// Grados desde el norte (de dónde viene el viento); opcional.
  final double? direccionViento;

  /// Código de condición del proveedor (p. ej. 500 = lluvia ligera); la app
  /// lo traduce a su propia frase en `Textos`.
  final int codigoClima;
  final String descripcion;
  final DateTime? salidaSol;
  final DateTime? puestaSol;

  /// ¿Es de día en el momento de la observación? Sin datos del sol, se
  /// toma de 6:00 a 18:00 en Guatemala.
  bool get esDeDia {
    final salida = salidaSol;
    final puesta = puestaSol;
    if (salida != null && puesta != null) {
      return !fechaHora.isBefore(salida) && fechaHora.isBefore(puesta);
    }
    final hora = fechaHora.toUtc().subtract(const Duration(hours: 6)).hour;
    return hora >= 6 && hora < 18;
  }

  /// Para la caché del teléfono (fechas en milisegundos UTC).
  Map<String, dynamic> toMap() => {
    'fechaHora': fechaHora.millisecondsSinceEpoch,
    'temperatura': temperatura,
    'sensacionTermica': sensacionTermica,
    'humedadRelativa': humedadRelativa,
    'lluviaUltimaHora': lluviaUltimaHora,
    'velocidadViento': velocidadViento,
    'direccionViento': direccionViento,
    'codigoClima': codigoClima,
    'descripcion': descripcion,
    'salidaSol': salidaSol?.millisecondsSinceEpoch,
    'puestaSol': puestaSol?.millisecondsSinceEpoch,
  };

  factory ClimaActual.fromMap(Map<String, dynamic> mapa) => ClimaActual(
    fechaHora: _fecha(mapa['fechaHora'])!,
    temperatura: (mapa['temperatura'] as num).toDouble(),
    sensacionTermica: (mapa['sensacionTermica'] as num).toDouble(),
    humedadRelativa: (mapa['humedadRelativa'] as num).toDouble(),
    lluviaUltimaHora: (mapa['lluviaUltimaHora'] as num? ?? 0).toDouble(),
    velocidadViento: (mapa['velocidadViento'] as num).toDouble(),
    direccionViento: (mapa['direccionViento'] as num?)?.toDouble(),
    codigoClima: mapa['codigoClima'] as int? ?? 800,
    descripcion: mapa['descripcion'] as String? ?? '',
    salidaSol: _fecha(mapa['salidaSol']),
    puestaSol: _fecha(mapa['puestaSol']),
  );

  static DateTime? _fecha(Object? milisegundos) => milisegundos is int
      ? DateTime.fromMillisecondsSinceEpoch(milisegundos, isUtc: true)
      : null;
}
