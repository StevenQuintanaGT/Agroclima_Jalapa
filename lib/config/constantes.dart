/// Valores de configuración compartidos. Los umbrales de alerta NO van aquí:
/// se leen de Firestore (RNF-19).
class Constantes {
  Constantes._();

  // Vigencia del dato guardado (DECISIONES D-08).
  static const Duration vigenciaCondiciones = Duration(minutes: 60);
  static const Duration vigenciaCondicionesAhorroDatos = Duration(minutes: 180);
  static const Duration vigenciaPronostico = Duration(hours: 3);

  // Celda climática: coordenadas redondeadas a 0.05° (DECISIONES D-07).
  static const double tamanoCeldaGrados = 0.05;

  // Rangos posibles para la región (VA-07, REQUISITOS §7).
  static const double temperaturaMinimaValida = -5;
  static const double temperaturaMaximaValida = 45;
  static const double humedadMinimaValida = 0;
  static const double humedadMaximaValida = 100;
  static const double lluviaMaximaValidaMmHora = 200;
  static const double vientoMaximoValidoKmHora = 200;

  // Validaciones de cuenta y parcela (VA-02, VA-05).
  static const int largoMinimoContrasena = 8;
  static const int largoMaximoNombreParcela = 40;
}
