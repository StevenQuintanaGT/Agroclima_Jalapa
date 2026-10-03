import 'package:agroclima_jalapa/modelos/clima_actual.dart';
import 'package:agroclima_jalapa/modelos/franja_pronostico.dart';
import 'package:agroclima_jalapa/modelos/pronostico_dia.dart';
import 'package:agroclima_jalapa/servicios/clima_servicio.dart';
import 'package:flutter_test/flutter_test.dart';

final _ahora = DateTime.utc(2026, 10, 3, 18); // 12:00 en Guatemala

FranjaPronostico _franja(int horas, {double pop = 0, double max = 19}) =>
    FranjaPronostico(
      fechaHora: _ahora.add(Duration(hours: horas)),
      temperatura: 18,
      temperaturaMinima: 16,
      temperaturaMaxima: max,
      humedadRelativa: 80,
      lluvia3h: 0,
      velocidadViento: 5,
      probabilidadLluvia: pop,
      codigoClima: 500,
    );

ClimaActual _actual(double temperatura) => ClimaActual(
  fechaHora: _ahora,
  temperatura: temperatura,
  sensacionTermica: temperatura,
  humedadRelativa: 80,
  lluviaUltimaHora: 0,
  velocidadViento: 5,
  codigoClima: 500,
);

void main() {
  test('la máxima de hoy no queda por debajo de la temperatura de ahora', () {
    final hoy = ClimaServicio.hoy(
      guardados: const [],
      franjas: [_franja(0), _franja(3)],
      ahora: _ahora,
      actual: _actual(20.4),
    )!;
    expect(hoy.temperaturaMaxima, 20.4);
    expect(hoy.temperaturaMinima, 16);
  });

  test('prefiere el resumen de todo el día que guardó el ciclo', () {
    final hoy = ClimaServicio.hoy(
      guardados: const [
        PronosticoDia(
          fecha: '20261003',
          temperaturaMinima: 12,
          temperaturaMaxima: 27,
          precipitacionHora: 0,
          acumuladoDia: 0,
          velocidadViento: 10,
          humedadRelativa: 70,
        ),
      ],
      franjas: [_franja(0)],
      ahora: _ahora,
      actual: _actual(20),
    )!;
    expect(hoy.temperaturaMaxima, 27);
    expect(hoy.temperaturaMinima, 12);
  });

  test('sin pronóstico no hay resumen', () {
    expect(
      ClimaServicio.hoy(guardados: const [], franjas: const [], ahora: _ahora),
      isNull,
    );
  });

  test('"Va a llover" mira las próximas 12 horas', () {
    final franjas = [
      _franja(-3, pop: 0.9), // ya terminó
      _franja(0, pop: 0.2),
      _franja(3, pop: 0.5),
      _franja(6),
      _franja(9),
      _franja(12, pop: 1), // fuera de las 12 horas
    ];
    expect(ClimaServicio.probabilidadLluvia(franjas, _ahora), 0.5);
    expect(ClimaServicio.probabilidadLluvia(const [], _ahora), isNull);
  });
}
