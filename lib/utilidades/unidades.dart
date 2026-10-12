/// Conversiones de unidades. Los datos se guardan siempre en métrico
/// (°C, mm, km/h, hectáreas o la unidad elegida) y se convierten solo al mostrar.
class Unidades {
  Unidades._();

  /// Cómo quiere ver los datos el productor (Ajustes, pantalla 29). Lo fija
  /// la raíz de la app cuando cambia el perfil y redibuja todo (D-55).
  static bool enFahrenheit = false;
  static bool enHectareas = false;

  /// Temperatura para mostrar; se guarda siempre en °C.
  static double temperatura(double celsius) =>
      enFahrenheit ? celsiusAFahrenheit(celsius) : celsius;

  static String get simboloTemperatura => enFahrenheit ? '°F' : '°C';

  /// Área para mostrar en la unidad elegida; [unidad] es la que se escribió
  /// al registrar la parcela (`manzana` o `hectarea`).
  static double area(double valor, String unidad) {
    final enManzanas = unidad == 'manzana';
    if (enHectareas == !enManzanas) return valor;
    return enHectareas ? manzanasAHectareas(valor) : hectareasAManzanas(valor);
  }

  /// 1 manzana = 0.6987 hectáreas (medida local de Guatemala).
  static const double hectareasPorManzana = 0.6987;

  static double celsiusAFahrenheit(double celsius) => celsius * 9 / 5 + 32;

  static double fahrenheitACelsius(double fahrenheit) =>
      (fahrenheit - 32) * 5 / 9;

  static double manzanasAHectareas(double manzanas) =>
      manzanas * hectareasPorManzana;

  static double hectareasAManzanas(double hectareas) =>
      hectareas / hectareasPorManzana;

  /// OpenWeather entrega el viento en m/s con `units=metric`.
  static double metrosPorSegundoAKmPorHora(double metrosPorSegundo) =>
      (metrosPorSegundo * 360).round() / 100;
}
