/// Condición del día de una parcela: `parcelas/{id}/condiciones/{yyyyMMdd}`
/// (Tabla 67). La escriben el ciclo (`origen: ciclo`) y la app al consultar
/// (`origen: consulta`).
class Condicion {
  const Condicion({
    required this.fecha,
    required this.fechaHora,
    required this.temperatura,
    required this.humedadRelativa,
    required this.velocidadViento,
    this.precipitacion,
    this.origen = 'consulta',
  });

  /// `yyyyMMdd` en hora de Guatemala (= id del documento).
  final String fecha;

  /// Momento de la observación (UTC).
  final DateTime fechaHora;
  final double temperatura;
  final double humedadRelativa;
  final double velocidadViento;

  /// mm acumulados del día; los calcula el ciclo (D-40). `null` si el ciclo
  /// todavía no pasó hoy.
  final double? precipitacion;
  final String origen;

  /// Lo que escribe la app: sin `precipitacion`, que es del ciclo, y sin la
  /// fecha, que el repositorio guarda como `Timestamp`.
  Map<String, dynamic> toMapConsulta() => {
    'fecha': fecha,
    'temperatura': temperatura,
    'humedadRelativa': humedadRelativa,
    'velocidadViento': velocidadViento,
    'origen': 'consulta',
    'vigente': true,
  };

  factory Condicion.fromMap(
    Map<String, dynamic> mapa, {
    required DateTime fechaHora,
  }) => Condicion(
    fecha: mapa['fecha'] as String,
    fechaHora: fechaHora,
    temperatura: (mapa['temperatura'] as num).toDouble(),
    humedadRelativa: (mapa['humedadRelativa'] as num).toDouble(),
    velocidadViento: (mapa['velocidadViento'] as num).toDouble(),
    precipitacion: (mapa['precipitacion'] as num?)?.toDouble(),
    origen: mapa['origen'] as String? ?? 'ciclo',
  );
}
