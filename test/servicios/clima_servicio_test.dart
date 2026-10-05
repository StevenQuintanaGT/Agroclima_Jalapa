import 'package:agroclima_jalapa/modelos/clima_actual.dart';
import 'package:agroclima_jalapa/modelos/franja_pronostico.dart';
import 'package:agroclima_jalapa/modelos/pronostico_dia.dart';
import 'package:agroclima_jalapa/config/textos.dart';
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

  group('días del pronóstico (HU-08)', () {
    final inicio = DateTime.utc(2026, 10, 3, 18); // 12:00 del día 3
    final franjas = [
      for (var i = 0; i < 16; i++)
        FranjaPronostico(
          fechaHora: inicio.add(Duration(hours: 3 * i)),
          temperatura: 20,
          temperaturaMinima: 15,
          temperaturaMaxima: 25,
          humedadRelativa: 80,
          lluvia3h: i == 5 ? 6 : 0,
          velocidadViento: 10,
          probabilidadLluvia: i == 5 ? 0.8 : 0.1,
          codigoClima: i == 5 ? 501 : 800,
        ),
    ];

    test('agrupa por día con ícono y probabilidad', () {
      final dias = ClimaServicio.dias(
        franjas: franjas,
        guardados: const [],
        ahora: inicio,
      );
      expect(dias.map((d) => d.fecha), ['20261003', '20261004', '20261005']);
      expect(dias[0].franjas, hasLength(4)); // 12, 15, 18 y 21 h
      expect(dias[1].codigoClima, 501); // la lluvia manda sobre el sol
      expect(dias[1].probabilidadLluvia, 0.8);
      expect(dias[1].acumuladoDia, 6);
      expect(dias[1].dia, DateTime.utc(2026, 10, 4));
      expect(dias[0].esHoy, isTrue);
      expect(dias[1].esHoy, isFalse);
    });

    test('de noche la lista empieza mañana y no se llama "Hoy"', () {
      final noche = DateTime.utc(2026, 10, 4, 4); // 3 oct, 22:00 en Guatemala
      final manana = franjas.where((f) => f.fechaHora.isAfter(noche)).toList();
      final dias = ClimaServicio.dias(
        franjas: manana,
        guardados: const [],
        ahora: noche,
      );
      expect(dias.first.fecha, '20261004');
      expect(dias.first.esHoy, isFalse);
    });

    test('sin franjas usa lo que guardó el ciclo', () {
      final dias = ClimaServicio.dias(
        franjas: const [],
        guardados: const [
          PronosticoDia(
            fecha: '20261002',
            temperaturaMinima: 1,
            temperaturaMaxima: 2,
            precipitacionHora: 0,
            acumuladoDia: 0,
            velocidadViento: 0,
            humedadRelativa: 0,
          ),
          PronosticoDia(
            fecha: '20261003',
            temperaturaMinima: 14,
            temperaturaMaxima: 27,
            precipitacionHora: 0,
            acumuladoDia: 0,
            velocidadViento: 9,
            humedadRelativa: 70,
          ),
        ],
        ahora: inicio,
      );
      expect(dias.single.fecha, '20261003');
      expect(dias.single.codigoClima, isNull);
    });
  });

  group('frases que interpretan las gráficas', () {
    test('la hora en palabras', () {
      expect(
        Textos.aLaHora(DateTime.utc(2026, 1, 1, 5)),
        'a las 5 de la mañana',
      );
      expect(
        Textos.aLaHora(DateTime.utc(2026, 1, 1, 13)),
        'a la 1 de la tarde',
      );
      expect(
        Textos.aLaHora(DateTime.utc(2026, 1, 1, 21)),
        'a las 9 de la noche',
      );
      expect(Textos.aLaHora(DateTime.utc(2026, 1, 1, 0)), 'a la medianoche');
      expect(
        Textos.aLaHora(DateTime.utc(2026, 1, 1, 12)),
        'a las 12 del mediodía',
      );
    });

    test('la intensidad de la lluvia (plans/03 §6)', () {
      expect(Textos.intensidadLluvia(1), 'lluvia ligera');
      expect(Textos.intensidadLluvia(5), 'lluvia moderada');
      expect(Textos.intensidadLluvia(20), 'lluvia fuerte');
      expect(
        Textos.totalEsperado(esHoy: true, mm: 6, mmHora: 2),
        'Total esperado hoy: 6 mm — lluvia ligera',
      );
      expect(
        Textos.totalEsperado(esHoy: false, mm: 0, mmHora: 0),
        'No se espera lluvia ese día',
      );
    });
  });
}
