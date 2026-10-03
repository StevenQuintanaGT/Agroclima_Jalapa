import 'franja_pronostico.dart';

/// Un día del pronóstico listo para mostrar (panel y detalle, HU-08): las
/// cifras de la Tabla 68 más lo que solo sirve en pantalla (ícono del día,
/// probabilidad de lluvia y sus franjas de 3 h).
class ResumenDia {
  const ResumenDia({
    required this.fecha,
    required this.dia,
    required this.temperaturaMinima,
    required this.temperaturaMaxima,
    required this.acumuladoDia,
    required this.precipitacionHora,
    required this.velocidadViento,
    required this.humedadRelativa,
    this.codigoClima,
    this.probabilidadLluvia,
    this.franjas = const [],
  });

  /// `yyyyMMdd` en hora de Guatemala.
  final String fecha;

  /// Medianoche de ese día (hora de pared de Guatemala, marcada como UTC).
  final DateTime dia;
  final double temperaturaMinima;
  final double temperaturaMaxima;
  final double acumuladoDia;

  /// Intensidad media máxima, mm/h.
  final double precipitacionHora;
  final double velocidadViento;
  final double humedadRelativa;

  /// El tiempo más fuerte del día; `null` si solo hay el resumen del ciclo.
  final int? codigoClima;

  /// De 0 a 1; `null` si solo hay el resumen del ciclo.
  final double? probabilidadLluvia;
  final List<FranjaPronostico> franjas;
}
