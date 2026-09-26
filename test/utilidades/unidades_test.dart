import 'package:agroclima_jalapa/utilidades/unidades.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unidades', () {
    test('°C a °F', () {
      expect(Unidades.celsiusAFahrenheit(0), 32);
      expect(Unidades.celsiusAFahrenheit(100), 212);
      expect(Unidades.celsiusAFahrenheit(-5), closeTo(23, 1e-9));
    });

    test('°F a °C es la inversa', () {
      expect(
        Unidades.fahrenheitACelsius(Unidades.celsiusAFahrenheit(24.5)),
        closeTo(24.5, 1e-9),
      );
    });

    test('1 manzana = 0.6987 hectáreas', () {
      expect(Unidades.manzanasAHectareas(1), closeTo(0.6987, 1e-9));
      expect(Unidades.manzanasAHectareas(10), closeTo(6.987, 1e-9));
      expect(Unidades.hectareasAManzanas(0.6987), closeTo(1, 1e-9));
    });

    test('m/s a km/h', () {
      expect(Unidades.metrosPorSegundoAKmPorHora(10), closeTo(36, 1e-9));
      expect(Unidades.metrosPorSegundoAKmPorHora(0), 0);
    });
  });
}
