/// Lo guardado de un día pasado en `parcelas/{id}/condiciones/{yyyyMMdd}`
/// (Tabla 67), para el historial (HU-13) y los reportes (HU-16). Todos los
/// valores pueden faltar: un día puede tener solo la consulta de la app o
/// solo la lluvia que cerró el ciclo.
class RegistroDia {
  const RegistroDia({
    required this.fecha,
    this.temperatura,
    this.temperaturaMinima,
    this.temperaturaMaxima,
    this.precipitacion,
  });

  /// `yyyyMMdd` en hora de Guatemala (= id del documento).
  final String fecha;

  /// Última temperatura registrada (°C).
  final double? temperatura;

  /// Mínima y máxima observadas por el ciclo (D-53).
  final double? temperaturaMinima;
  final double? temperaturaMaxima;

  /// mm del día que sumó el ciclo (D-40); `null` si no pasó ese día.
  final double? precipitacion;

  /// Día del calendario (medianoche UTC del mismo año, mes y día).
  DateTime get dia => DateTime.utc(
    int.parse(fecha.substring(0, 4)),
    int.parse(fecha.substring(4, 6)),
    int.parse(fecha.substring(6, 8)),
  );

  factory RegistroDia.fromMap(String fecha, Map<String, dynamic> mapa) {
    double? numero(String campo) => (mapa[campo] as num?)?.toDouble();
    return RegistroDia(
      fecha: fecha,
      temperatura: numero('temperatura'),
      temperaturaMinima: numero('temperaturaMinima'),
      temperaturaMaxima: numero('temperaturaMaxima'),
      precipitacion: numero('precipitacion'),
    );
  }
}
