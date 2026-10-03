/// Pronóstico de un día: `parcelas/{id}/pronosticos/{yyyyMMdd}` (Tabla 68).
/// Es el único insumo del motor de alertas. Lo escribe solo el ciclo de la
/// nube; la app lo lee (y lo calcula en el teléfono mientras no haya uno
/// guardado).
class PronosticoDia {
  const PronosticoDia({
    required this.fecha,
    required this.temperaturaMinima,
    required this.temperaturaMaxima,
    required this.precipitacionHora,
    required this.acumuladoDia,
    required this.velocidadViento,
    required this.humedadRelativa,
    this.fechaConsulta,
  });

  /// `yyyyMMdd` en hora de Guatemala (= id del documento).
  final String fecha;
  final double temperaturaMinima;
  final double temperaturaMaxima;

  /// Intensidad media máxima del día, mm/h.
  final double precipitacionHora;

  /// mm totales del día.
  final double acumuladoDia;

  /// Máxima del día, km/h.
  final double velocidadViento;

  /// Promedio del día, %.
  final double humedadRelativa;
  final DateTime? fechaConsulta;

  /// Sin `fechaConsulta`: la pone el servidor al guardar.
  Map<String, dynamic> toMap() => {
    'fecha': fecha,
    'temperaturaMinima': temperaturaMinima,
    'temperaturaMaxima': temperaturaMaxima,
    'precipitacionHora': precipitacionHora,
    'acumuladoDia': acumuladoDia,
    'velocidadViento': velocidadViento,
    'humedadRelativa': humedadRelativa,
  };

  factory PronosticoDia.fromMap(
    Map<String, dynamic> mapa, {
    DateTime? fechaConsulta,
  }) => PronosticoDia(
    fecha: mapa['fecha'] as String,
    temperaturaMinima: (mapa['temperaturaMinima'] as num).toDouble(),
    temperaturaMaxima: (mapa['temperaturaMaxima'] as num).toDouble(),
    precipitacionHora: (mapa['precipitacionHora'] as num? ?? 0).toDouble(),
    acumuladoDia: (mapa['acumuladoDia'] as num? ?? 0).toDouble(),
    velocidadViento: (mapa['velocidadViento'] as num).toDouble(),
    humedadRelativa: (mapa['humedadRelativa'] as num).toDouble(),
    fechaConsulta: fechaConsulta,
  );
}
