/// Espaciado, radios y alturas táctiles (handoff de diseño, Tabla 74).
class Medidas {
  Medidas._();

  // Escala de 8.
  static const double espacioXs = 8;
  static const double espacioS = 16;
  static const double espacioM = 24;
  static const double espacioL = 32;
  static const double espacioXl = 48;

  static const double margenPantalla = 16;
  static const double margenPantallaCentrada = 28;
  static const double separacionTarjetas = 12;

  // Radios.
  static const double radioChico = 8;
  static const double radioCampo = 12;
  static const double radioBoton = 14;
  static const double radioTarjeta = 16;
  static const double radioPildora = 24;
  static const double radioHoja = 26;

  // Alturas táctiles (mínimo 48 dp en todo elemento interactivo).
  static const double minimoTactil = 48;
  static const double alturaBotonPrincipal = 60;
  static const double alturaBotonSecundario = 56;
  static const double alturaCampo = 56;
  static const double alturaFila = 56;
}
