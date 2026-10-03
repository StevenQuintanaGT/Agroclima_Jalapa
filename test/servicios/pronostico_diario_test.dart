import 'package:agroclima_jalapa/modelos/franja_pronostico.dart';
import 'package:agroclima_jalapa/servicios/pronostico_diario.dart';
import 'package:agroclima_jalapa/servicios/validacion_clima.dart';
import 'package:flutter_test/flutter_test.dart';

FranjaPronostico _franja(
  DateTime utc, {
  double minima = 15,
  double maxima = 25,
  double humedad = 80,
  double lluvia = 0,
  double viento = 10,
}) => FranjaPronostico(
  fechaHora: utc,
  temperatura: (minima + maxima) / 2,
  temperaturaMinima: minima,
  temperaturaMaxima: maxima,
  humedadRelativa: humedad,
  lluvia3h: lluvia,
  velocidadViento: viento,
  codigoClima: 800,
);

void main() {
  group('agrupar por día (D-10)', () {
    test('el día se corta a medianoche de Guatemala, no de UTC', () {
      final dias = PronosticoDiario.agrupar([
        _franja(DateTime.utc(2026, 10, 4, 3)), // 3 oct, 21:00 en Guatemala
        _franja(DateTime.utc(2026, 10, 4, 6)), // 4 oct, 00:00 en Guatemala
      ]);
      expect(dias.map((d) => d.fecha), ['20261003', '20261004']);
    });

    test('calcula mínimos, máximos, acumulado y promedio', () {
      final dia = PronosticoDiario.agrupar([
        _franja(
          DateTime.utc(2026, 10, 3, 6),
          minima: 12,
          lluvia: 3,
          humedad: 90,
        ),
        _franja(
          DateTime.utc(2026, 10, 3, 9),
          maxima: 28,
          lluvia: 15,
          viento: 40,
        ),
        _franja(DateTime.utc(2026, 10, 3, 12), humedad: 60),
      ]).single;
      expect(dia.temperaturaMinima, 12);
      expect(dia.temperaturaMaxima, 28);
      expect(dia.acumuladoDia, 18);
      expect(dia.precipitacionHora, 5); // 15 mm en 3 h
      expect(dia.velocidadViento, 40);
      expect(dia.humedadRelativa, 76.67);
    });

    test('devuelve solo hoy y los 4 días siguientes, en orden', () {
      final inicio = DateTime.utc(2026, 10, 3, 6);
      final franjas = [
        for (var i = 0; i < 40; i++)
          _franja(inicio.add(Duration(hours: 3 * i))),
      ]..shuffle();
      final dias = PronosticoDiario.agrupar(franjas);
      expect(dias.map((d) => d.fecha), [
        '20261003',
        '20261004',
        '20261005',
        '20261006',
        '20261007',
      ]);
    });

    test('sin franjas no hay días', () {
      expect(PronosticoDiario.agrupar(const []), isEmpty);
    });

    test('usa los nombres de campo de la Tabla 68', () {
      final dia = PronosticoDiario.agrupar([
        _franja(DateTime.utc(2026, 10, 3, 6)),
      ]).single;
      expect(dia.toMap().keys, [
        'fecha',
        'temperaturaMinima',
        'temperaturaMaxima',
        'precipitacionHora',
        'acumuladoDia',
        'velocidadViento',
        'humedadRelativa',
      ]);
    });
  });

  group('validaciones', () {
    test('rangos posibles para la región (VA-07)', () {
      expect(
        ValidacionClima.enRango(
          temperatura: 20,
          humedadRelativa: 50,
          velocidadViento: 30,
        ),
        isTrue,
      );
      expect(
        ValidacionClima.enRango(
          temperatura: -6,
          humedadRelativa: 50,
          velocidadViento: 30,
        ),
        isFalse,
      );
      expect(
        ValidacionClima.enRango(
          temperatura: 20,
          humedadRelativa: 50,
          velocidadViento: 30,
          lluviaPorHora: 250,
        ),
        isFalse,
      );
    });

    test('solo se acepta un dato más nuevo que el guardado (VA-08)', () {
      final antes = DateTime.utc(2026, 10, 3, 12);
      final despues = DateTime.utc(2026, 10, 3, 15);
      expect(ValidacionClima.esPosterior(despues, antes), isTrue);
      expect(ValidacionClima.esPosterior(antes, despues), isFalse);
      expect(ValidacionClima.esPosterior(antes, antes), isFalse);
      expect(ValidacionClima.esPosterior(antes, null), isTrue);
    });
  });

  test('la franja se guarda y se lee igual (caché local, D-12)', () {
    final franja = _franja(DateTime.utc(2026, 10, 3, 6), lluvia: 2.5);
    final copia = FranjaPronostico.fromMap(franja.toMap());
    expect(copia.fechaHora, franja.fechaHora);
    expect(copia.lluvia3h, 2.5);
    expect(copia.temperaturaMaxima, franja.temperaturaMaxima);
  });
}
