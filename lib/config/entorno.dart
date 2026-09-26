/// Claves que llegan con `--dart-define-from-file=env/dev.json` (RNF-04).
/// Nunca se escriben en el código ni se suben al repositorio.
class Entorno {
  Entorno._();

  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
  );

  static bool get tieneClaveOpenWeather => openWeatherApiKey.isNotEmpty;
}
