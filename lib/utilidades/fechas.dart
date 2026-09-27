/// Fechas en hora de Guatemala (`America/Guatemala`).
///
/// Guatemala usa UTC-6 todo el año (sin horario de verano), así que basta con
/// un desfase fijo y no hace falta una base de datos de zonas horarias.
class Fechas {
  Fechas._();

  static const Duration desfaseGuatemala = Duration(hours: -6);

  /// Convierte un instante a la hora de pared de Guatemala.
  ///
  /// El resultado se marca como UTC solo para que sus campos (año, mes, día,
  /// hora) no dependan de la zona horaria del teléfono; no representa UTC.
  static DateTime aHoraGuatemala(DateTime instante) =>
      instante.toUtc().add(desfaseGuatemala);

  /// Id diario `yyyyMMdd` de `condiciones` y `pronosticos` (MODELO_DATOS §1).
  static String idDiario(DateTime instante) {
    final local = aHoraGuatemala(instante);
    final mes = local.month.toString().padLeft(2, '0');
    final dia = local.day.toString().padLeft(2, '0');
    return '${local.year}$mes$dia';
  }
}
