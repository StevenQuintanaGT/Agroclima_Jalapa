/// Conversiones de unidades. Los datos se guardan siempre en métrico
/// (°C, mm, km/h, hectáreas o la unidad elegida) y se convierten solo al mostrar.
class Unidades {
  Unidades._();

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
      metrosPorSegundo * 3.6;
}
