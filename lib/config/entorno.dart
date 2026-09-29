/// Claves que llegan con `--dart-define-from-file=env/dev.json` (RNF-04).
/// Nunca se escriben en el código ni se suben al repositorio.
class Entorno {
  Entorno._();

  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
  );

  static bool get tieneClaveOpenWeather => openWeatherApiKey.isNotEmpty;

  /// Solo desarrollo: `--dart-define=USAR_EMULADORES=true` conecta la app a
  /// los emuladores de Firebase de la PC (auth 9099, firestore 8080) en vez
  /// del proyecto real. En el emulador de Android la PC es 10.0.2.2.
  static const bool usarEmuladores = bool.fromEnvironment('USAR_EMULADORES');
  static const String hostEmuladores = String.fromEnvironment(
    'HOST_EMULADORES',
    defaultValue: '10.0.2.2',
  );
}
