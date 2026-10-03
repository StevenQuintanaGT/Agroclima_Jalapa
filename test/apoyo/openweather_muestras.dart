// Respuestas de ejemplo con el formato de OpenWeather 2.5 (units=metric).

/// 2026-10-03 12:00 hora de Guatemala = 18:00 UTC.
const int mediodia3Oct = 1791050400;

Map<String, dynamic> actualMuestra({
  Object? temperatura = 24.5,
  Object? humedad = 70,
  Object? viento = 5,
  double? lluvia1h,
  int dt = mediodia3Oct,
}) => {
  'coord': {'lon': -89.99, 'lat': 14.63},
  'weather': [
    {'id': 500, 'main': 'Rain', 'description': 'lluvia ligera', 'icon': '10d'},
  ],
  'main': {
    'temp': ?temperatura,
    'feels_like': 25.1,
    'temp_min': 23.0,
    'temp_max': 26.0,
    'humidity': ?humedad,
  },
  'wind': {'speed': ?viento, 'deg': 40},
  'rain': ?(lluvia1h == null ? null : {'1h': lluvia1h}),
  'dt': dt,
  'sys': {'sunrise': 1791029400, 'sunset': 1791072300},
};

/// Una franja de 3 h que empieza en [dt] (segundos UTC).
Map<String, dynamic> franjaMuestra(
  int dt, {
  double temperatura = 20,
  double minima = 18,
  double maxima = 22,
  double humedad = 80,
  double viento = 3,
  double? lluvia3h,
  double pop = 0.4,
}) => {
  'dt': dt,
  'main': {
    'temp': temperatura,
    'temp_min': minima,
    'temp_max': maxima,
    'humidity': humedad,
  },
  'weather': [
    {'id': 802, 'description': 'nubes dispersas'},
  ],
  'wind': {'speed': viento},
  'pop': pop,
  'rain': ?(lluvia3h == null ? null : {'3h': lluvia3h}),
};

/// 40 franjas desde el 3 de octubre a las 00:00 hora de Guatemala.
Map<String, dynamic> pronosticoMuestra() {
  const inicio = 1791007200; // 2026-10-03 06:00 UTC
  return {
    'cnt': 40,
    'list': [for (var i = 0; i < 40; i++) franjaMuestra(inicio + i * 10800)],
  };
}
