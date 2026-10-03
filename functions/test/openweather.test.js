'use strict';

const { crearCliente, ErrorClima } = require('../src/openweather');
const { agruparPorDia } = require('../src/pronostico_diario');
const { idDiario } = require('../src/fechas');
const { enRango, esPosterior } = require('../src/validacion');

// 2026-10-03 06:00 UTC = 00:00 en Guatemala.
const INICIO = Date.UTC(2026, 9, 3, 6) / 1000;

function franja(dt, extra = {}) {
  return {
    dt,
    main: { temp: 20, temp_min: 18, temp_max: 22, humidity: 80, ...extra.main },
    wind: { speed: 3, ...extra.wind },
    weather: [{ id: 802, description: 'nubes dispersas' }],
    pop: 0.4,
    ...(extra.rain ? { rain: extra.rain } : {}),
  };
}

const actualMuestra = (main = {}) => ({
  dt: INICIO + 12 * 3600,
  main: { temp: 24.5, feels_like: 25.1, humidity: 70, ...main },
  wind: { speed: 5 },
  rain: { '1h': 1.2 },
  weather: [{ id: 500, description: 'lluvia ligera' }],
});

/** fetch falso: devuelve en orden las respuestas dadas (o lanza si es Error). */
function fetchFalso(...respuestas) {
  const pedidas = [];
  const pedirHttp = async (url) => {
    pedidas.push(new URL(url));
    const siguiente = respuestas.shift();
    if (siguiente instanceof Error) throw siguiente;
    const { estado = 200, cuerpo } = siguiente;
    return {
      status: estado,
      ok: estado >= 200 && estado < 300,
      json: async () => {
        if (typeof cuerpo === 'string') throw new SyntaxError('no es JSON');
        return cuerpo;
      },
    };
  };
  return { pedirHttp, pedidas };
}

const sinEspera = async () => {};

describe('cliente OpenWeather del ciclo', () => {
  test('pide Current Weather 2.5 en métrico y español, y traduce', async () => {
    const { pedirHttp, pedidas } = fetchFalso({ cuerpo: actualMuestra() });
    const cliente = crearCliente({ clave: 'k', pedirHttp, esperar: sinEspera });

    const clima = await cliente.actual(14.63391, -89.98889);

    const url = pedidas[0];
    expect(url.origin + url.pathname).toBe('https://api.openweathermap.org/data/2.5/weather');
    expect(Object.fromEntries(url.searchParams)).toEqual({
      lat: '14.6339',
      lon: '-89.9889',
      units: 'metric',
      lang: 'es',
      appid: 'k',
    });
    expect(clima).toMatchObject({
      temperatura: 24.5,
      humedadRelativa: 70,
      lluviaUltimaHora: 1.2,
      velocidadViento: 18,
      codigoClima: 500,
    });
    expect(clima.fechaHora.toISOString()).toBe('2026-10-03T18:00:00.000Z');
  });

  test('respuesta incompleta o imposible se descarta (VA-06, VA-07)', async () => {
    const { pedirHttp } = fetchFalso(
      { cuerpo: actualMuestra({ humidity: undefined }) },
      { cuerpo: actualMuestra({ temp: 60 }) },
    );
    const cliente = crearCliente({ clave: 'k', pedirHttp, esperar: sinEspera });
    await expect(cliente.actual(14.6, -90)).rejects.toMatchObject({ motivo: 'respuestaInvalida' });
    await expect(cliente.actual(14.6, -90)).rejects.toMatchObject({ motivo: 'respuestaInvalida' });
  });

  test('reintenta lo pasajero con espera creciente', async () => {
    const esperas = [];
    const { pedirHttp, pedidas } = fetchFalso(
      new TypeError('fetch failed'),
      { estado: 503, cuerpo: {} },
      { cuerpo: actualMuestra() },
    );
    const cliente = crearCliente({
      clave: 'k',
      pedirHttp,
      esperar: async (ms) => esperas.push(ms),
    });

    await cliente.actual(14.6, -90);

    expect(pedidas).toHaveLength(3);
    expect(esperas).toEqual([1000, 2000]);
  });

  test('se rinde tras los reintentos y dice por qué', async () => {
    const { pedirHttp, pedidas } = fetchFalso(
      ...Array.from({ length: 4 }, () => ({ estado: 429, cuerpo: {} })),
    );
    const cliente = crearCliente({ clave: 'k', pedirHttp, esperar: sinEspera });
    await expect(cliente.pronostico(14.6, -90)).rejects.toMatchObject({
      motivo: 'limiteAlcanzado',
    });
    expect(pedidas).toHaveLength(4);
  });

  test('una clave rechazada no se reintenta', async () => {
    const { pedirHttp, pedidas } = fetchFalso({ estado: 401, cuerpo: {} });
    const cliente = crearCliente({ clave: 'k', pedirHttp, esperar: sinEspera });
    await expect(cliente.actual(14.6, -90)).rejects.toBeInstanceOf(ErrorClima);
    expect(pedidas).toHaveLength(1);
  });

  test('tiempo agotado se reconoce', async () => {
    const agotado = Object.assign(new Error('timeout'), { name: 'TimeoutError' });
    const { pedirHttp } = fetchFalso(agotado, agotado, agotado, agotado);
    const cliente = crearCliente({ clave: 'k', pedirHttp, esperar: sinEspera });
    await expect(cliente.actual(14.6, -90)).rejects.toMatchObject({ motivo: 'tiempoAgotado' });
  });

  test('sin clave no arranca', () => {
    expect(() => crearCliente({ clave: '' })).toThrow('OPENWEATHER_KEY');
  });

  test('pronóstico: franjas en orden, lluvia y viento traducidos', async () => {
    const lista = Array.from({ length: 40 }, (_, i) => franja(INICIO + i * 10800)).reverse();
    lista[0] = franja(INICIO + 39 * 10800, { rain: { '3h': 9 }, wind: { speed: 10 } });
    const { pedirHttp } = fetchFalso({ cuerpo: { list: lista } });
    const cliente = crearCliente({ clave: 'k', pedirHttp, esperar: sinEspera });

    const franjas = await cliente.pronostico(14.6, -90);

    expect(franjas).toHaveLength(40);
    expect(franjas[0].fechaHora.toISOString()).toBe('2026-10-03T06:00:00.000Z');
    expect(franjas[39]).toMatchObject({ lluvia3h: 9, velocidadViento: 36 });
  });

  test('una franja imposible descarta todo el pronóstico', async () => {
    const lista = [franja(INICIO), franja(INICIO + 10800, { main: { humidity: 140 } })];
    const { pedirHttp } = fetchFalso({ cuerpo: { list: lista } });
    const cliente = crearCliente({ clave: 'k', pedirHttp, esperar: sinEspera });
    await expect(cliente.pronostico(14.6, -90)).rejects.toMatchObject({
      motivo: 'respuestaInvalida',
    });
  });
});

describe('pronóstico por día (D-10)', () => {
  const dominio = (horaUtc, extra = {}) => ({
    fechaHora: new Date(horaUtc),
    temperaturaMinima: 15,
    temperaturaMaxima: 25,
    humedadRelativa: 80,
    lluvia3h: 0,
    velocidadViento: 10,
    ...extra,
  });

  test('corta el día a medianoche de Guatemala', () => {
    const dias = agruparPorDia([
      dominio(Date.UTC(2026, 9, 4, 3)),
      dominio(Date.UTC(2026, 9, 4, 6)),
    ]);
    expect(dias.map((d) => d.fecha)).toEqual(['20261003', '20261004']);
  });

  test('mínimos, máximos, acumulado, intensidad y promedio', () => {
    const [dia] = agruparPorDia([
      dominio(Date.UTC(2026, 9, 3, 6), { temperaturaMinima: 12, lluvia3h: 3, humedadRelativa: 90 }),
      dominio(Date.UTC(2026, 9, 3, 9), { temperaturaMaxima: 28, lluvia3h: 15, velocidadViento: 40 }),
      dominio(Date.UTC(2026, 9, 3, 12), { humedadRelativa: 60 }),
    ]);
    expect(dia).toEqual({
      fecha: '20261003',
      temperaturaMinima: 12,
      temperaturaMaxima: 28,
      precipitacionHora: 5,
      acumuladoDia: 18,
      velocidadViento: 40,
      humedadRelativa: 76.67,
    });
  });

  test('solo hoy y los 4 días siguientes', () => {
    const franjas = Array.from({ length: 40 }, (_, i) =>
      dominio(Date.UTC(2026, 9, 3, 6) + i * 3 * 3600 * 1000),
    );
    expect(agruparPorDia(franjas).map((d) => d.fecha)).toEqual([
      '20261003',
      '20261004',
      '20261005',
      '20261006',
      '20261007',
    ]);
  });
});

describe('fechas y validaciones', () => {
  test('id diario en hora de Guatemala', () => {
    expect(idDiario(new Date(Date.UTC(2026, 9, 4, 5, 59)))).toBe('20261003');
    expect(idDiario(new Date(Date.UTC(2026, 9, 4, 6, 0)))).toBe('20261004');
  });

  test('rangos posibles para la región (VA-07)', () => {
    expect(enRango({ temperatura: 20, humedadRelativa: 50, velocidadViento: 30 })).toBe(true);
    expect(enRango({ temperatura: 46, humedadRelativa: 50, velocidadViento: 30 })).toBe(false);
    expect(enRango({ temperatura: 20, humedadRelativa: NaN, velocidadViento: 30 })).toBe(false);
  });

  test('solo un dato más nuevo que el guardado (VA-08)', () => {
    const antes = new Date(Date.UTC(2026, 9, 3, 12));
    const despues = new Date(Date.UTC(2026, 9, 3, 15));
    expect(esPosterior(despues, antes)).toBe(true);
    expect(esPosterior(antes, antes)).toBe(false);
    expect(esPosterior(antes, null)).toBe(true);
  });
});
