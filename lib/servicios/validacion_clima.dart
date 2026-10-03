import '../config/constantes.dart';

/// Validaciones de los datos del clima antes de usarlos o guardarlos
/// (REQUISITOS §7). Lo que no pasa se descarta y queda el dato previo.
class ValidacionClima {
  ValidacionClima._();

  /// VA-07: valores posibles para la región.
  static bool enRango({
    required double temperatura,
    required double humedadRelativa,
    required double velocidadViento,
    double lluviaPorHora = 0,
  }) =>
      temperatura >= Constantes.temperaturaMinimaValida &&
      temperatura <= Constantes.temperaturaMaximaValida &&
      humedadRelativa >= Constantes.humedadMinimaValida &&
      humedadRelativa <= Constantes.humedadMaximaValida &&
      velocidadViento >= 0 &&
      velocidadViento <= Constantes.vientoMaximoValidoKmHora &&
      lluviaPorHora >= 0 &&
      lluviaPorHora <= Constantes.lluviaMaximaValidaMmHora;

  /// VA-08: el dato nuevo debe ser posterior al último guardado.
  static bool esPosterior(DateTime nuevo, DateTime? ultimoGuardado) =>
      ultimoGuardado == null || nuevo.isAfter(ultimoGuardado);
}
