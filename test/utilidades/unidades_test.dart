import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
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

  group('al mostrar, según Ajustes (D-55)', () {
    tearDown(() {
      Unidades.enFahrenheit = false;
      Unidades.enHectareas = false;
    });

    test('°C por defecto, °F si lo eligió; se guarda en °C', () {
      expect(Textos.grados(18.4), '18°');
      expect(Textos.gradosConUnidad(2), '2 °C');
      Unidades.enFahrenheit = true;
      expect(Textos.grados(18.4), '65°');
      expect(Textos.gradosConUnidad(0), '32 °F');
      expect(Textos.valorAlerta(TipoRiesgo.temperaturaBaja, 2), '36 °F');
      expect(
        Textos.valorAlerta(TipoRiesgo.lluviaIntensa, 20),
        '20 mm por hora',
      );
    });

    test('el área se muestra en la unidad elegida', () {
      expect(Textos.area(2, 'manzana'), '2 manzanas');
      expect(Textos.area(1.4, 'hectarea'), '2 manzanas');
      Unidades.enHectareas = true;
      expect(Textos.area(2, 'manzana'), '1.4 ha');
      expect(Textos.area(3, 'hectarea'), '3 ha');
    });
  });
}
