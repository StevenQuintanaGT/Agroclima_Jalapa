'use strict';

const catalogoSemilla = require('../seed/umbrales.json');
const { evaluarParcela } = require('../src/motor/evaluador');
const { definitorio, cumple } = require('../src/motor/comparar');
const { rachaDelHistorial } = require('../src/motor/reglas/sequia');
const { diaAnterior } = require('../src/fechas');

const catalogo = catalogoSemilla.map((u) => ({ cultivo: '', etapa: '', duracionDias: 1, ...u }));

/** Cinco días desde el lunes 5 de octubre de 2026, sin ningún riesgo. */
const FECHAS = ['20261005', '20261006', '20261007', '20261008', '20261009'];
const tranquilo = (fecha) => ({
  fecha,
  temperaturaMinima: 19,
  temperaturaMaxima: 26,
  precipitacionHora: 0.5,
  acumuladoDia: 4,
  velocidadViento: 8,
  humedadRelativa: 70,
});
/** Pronóstico tranquilo con cambios por día: { índice: { campo: valor } }. */
const pronostico = (cambios = {}) =>
  FECHAS.map((fecha, i) => ({ ...tranquilo(fecha), ...(cambios[i] ?? {}) }));
/** Historial de días pasados (el último es el domingo 4). */
const historial = (lluvias) => {
  let fecha = FECHAS[0];
  return lluvias
    .slice()
    .reverse()
    .map((precipitacion) => {
      fecha = diaAnterior(fecha);
      return { fecha, precipitacion };
    })
    .reverse();
};

const evaluar = (parcela, pronosticos, hist = [], cat = catalogo) =>
  evaluarParcela({ parcela, pronosticos, historial: hist, catalogo: cat, registrar: () => {} });
const sinCultivo = { cultivo: '', etapa: '' };

describe('casos de la Tabla 31 (plans/04, HT-04)', () => {
  test('café con 3 días > 30 °C → PELIGRO esos tres días', () => {
    const calor = { temperaturaMaxima: 31.5 };
    const r = evaluar({ cultivo: 'cafe', etapa: 'floracion' }, pronostico({ 1: calor, 2: calor, 3: calor }));
    expect(r).toEqual(
      [1, 2, 3].map((i) => ({
        tipoRiesgo: 'temperaturaAlta',
        nivel: 'critica',
        valorEsperado: 31.5,
        valorUmbral: 30,
        fechaEvento: FECHAS[i],
        umbralId: 'tmax_cafe_critica',
        diasConsecutivos: 3,
      })),
    );
  });

  test('café con solo 2 días > 30 °C → PRECAUCIÓN', () => {
    const calor = { temperaturaMaxima: 31 };
    const r = evaluar({ cultivo: 'cafe', etapa: '' }, pronostico({ 0: calor, 1: calor, 3: calor }));
    expect(r.map((x) => [x.fechaEvento, x.nivel])).toEqual([
      [FECHAS[0], 'preventiva'],
      [FECHAS[1], 'preventiva'],
      [FECHAS[3], 'preventiva'],
    ]);
    expect(r[0].diasConsecutivos).toBeUndefined();
  });

  test('maíz en floración con 7 días secos → PRECAUCIÓN (adelanta la informativa general)', () => {
    const seco = { acumuladoDia: 0.2, precipitacionHora: 0.1 };
    const r = evaluar(
      { cultivo: 'maiz', etapa: 'floracion' },
      pronostico({ 0: seco, 1: seco, 2: seco, 3: seco, 4: seco }),
      historial([6, 0, 0.4]),
    );
    expect(r).toEqual([
      {
        tipoRiesgo: 'sequia',
        nivel: 'preventiva',
        valorEsperado: 7,
        valorUmbral: 5,
        // 2 días secos del historial + 3 del pronóstico = 5 el miércoles.
        fechaEvento: FECHAS[2],
        umbralId: 'sequia_maiz_floracion_preventiva',
        diasConsecutivos: 7,
      },
    ]);
  });

  test('frijol con mínima de 17 °C → PRECAUCIÓN', () => {
    const r = evaluar({ cultivo: 'frijol', etapa: 'siembra' }, pronostico({ 2: { temperaturaMinima: 17 } }));
    expect(r).toEqual([
      expect.objectContaining({
        tipoRiesgo: 'temperaturaBaja',
        nivel: 'preventiva',
        valorEsperado: 17,
        valorUmbral: 18,
        fechaEvento: FECHAS[2],
      }),
    ]);
  });

  test('hortalizas con 16 °C → nada', () => {
    expect(evaluar({ cultivo: 'hortalizas', etapa: 'floracion' }, pronostico({ 0: { temperaturaMinima: 16 } }))).toEqual([]);
  });

  test('parcela sin cultivo con −1 °C → PELIGRO por helada (RN-05)', () => {
    const r = evaluar(sinCultivo, pronostico({ 4: { temperaturaMinima: -1 } }));
    expect(r).toEqual([
      expect.objectContaining({
        tipoRiesgo: 'temperaturaBaja',
        nivel: 'critica',
        valorUmbral: 0,
        umbralId: 'tmin_general_critica',
        fechaEvento: FECHAS[4],
      }),
    ]);
  });

  test('lluvia de 20 mm/h → PRECAUCIÓN; 35 mm/h → PELIGRO', () => {
    const r = evaluar(sinCultivo, pronostico({ 0: { precipitacionHora: 20 }, 1: { precipitacionHora: 35 } }));
    expect(r.map((x) => [x.tipoRiesgo, x.fechaEvento, x.nivel, x.valorUmbral])).toEqual([
      ['lluviaIntensa', FECHAS[0], 'preventiva', 15],
      ['lluviaIntensa', FECHAS[1], 'critica', 30],
    ]);
  });
});

describe('reglas diarias', () => {
  test('justo en el umbral no cumple con "mayor" y sí con "menorIgual"', () => {
    expect(evaluar(sinCultivo, pronostico({ 0: { velocidadViento: 15 } }))).toEqual([]);
    expect(evaluar(sinCultivo, pronostico({ 0: { temperaturaMinima: 0 } }))[0].nivel).toBe('critica');
  });

  test('viento de 32 km/h → PELIGRO, de 20 km/h → PRECAUCIÓN', () => {
    const r = evaluar(sinCultivo, pronostico({ 0: { velocidadViento: 32 }, 1: { velocidadViento: 20 } }));
    expect(r.map((x) => x.nivel)).toEqual(['critica', 'preventiva']);
  });

  test('café con helada: manda la helada general, no el frío del café', () => {
    const r = evaluar({ cultivo: 'cafe', etapa: '' }, pronostico({ 0: { temperaturaMinima: -0.5 } }));
    expect(r).toEqual([expect.objectContaining({ nivel: 'critica', umbralId: 'tmin_general_critica' })]);
  });

  test('café con 14 °C → PRECAUCIÓN con lo que aguanta el café (15 °C)', () => {
    const r = evaluar({ cultivo: 'cafe', etapa: '' }, pronostico({ 0: { temperaturaMinima: 14 } }));
    expect(r).toEqual([expect.objectContaining({ nivel: 'preventiva', valorUmbral: 15 })]);
  });

  test('café con humedad de 90 % → PRECAUCIÓN; maíz con 90 % → nada', () => {
    const humedo = pronostico({ 1: { humedadRelativa: 90 } });
    expect(evaluar({ cultivo: 'cafe', etapa: '' }, humedo)).toEqual([
      expect.objectContaining({ tipoRiesgo: 'humedadAlta', nivel: 'preventiva', fechaEvento: FECHAS[1] }),
    ]);
    expect(evaluar({ cultivo: 'maiz', etapa: 'floracion' }, humedo)).toEqual([]);
  });

  test('maíz con 36 °C: PRECAUCIÓN creciendo, PELIGRO floreando, nada en cosecha', () => {
    const calor = pronostico({ 0: { temperaturaMaxima: 36 } });
    const nivel = (etapa) => evaluar({ cultivo: 'maiz', etapa }, calor).map((x) => x.nivel);
    expect(nivel('desarrolloVegetativo')).toEqual(['preventiva']);
    expect(nivel('floracion')).toEqual(['critica']);
    expect(nivel('llenado')).toEqual(['critica']);
    expect(nivel('cosecha')).toEqual([]);
  });

  test('frijol con 4 días > 28 °C: los 4 en PELIGRO con racha de 4', () => {
    const calor = { temperaturaMaxima: 29 };
    const r = evaluar({ cultivo: 'frijol', etapa: '' }, pronostico({ 1: calor, 2: calor, 3: calor, 4: calor }));
    expect(r.map((x) => [x.nivel, x.diasConsecutivos])).toEqual(Array(4).fill(['critica', 4]));
  });

  test('como máximo un resultado por riesgo y día, con varios riesgos el mismo día', () => {
    const r = evaluar(
      { cultivo: 'cafe', etapa: '' },
      pronostico({ 0: { velocidadViento: 40, precipitacionHora: 18, temperaturaMinima: 12 } }),
    );
    expect(r.map((x) => [x.tipoRiesgo, x.nivel])).toEqual([
      ['lluviaIntensa', 'preventiva'],
      ['temperaturaBaja', 'preventiva'],
      ['vientoFuerte', 'critica'],
    ]);
  });

  test('solo evalúa 5 días, en orden de fecha, aunque lleguen desordenados', () => {
    const dias = pronostico({ 0: { velocidadViento: 20 } }).reverse();
    dias.push({ ...tranquilo('20261010'), velocidadViento: 50 });
    const r = evaluar(sinCultivo, dias);
    expect(r.map((x) => x.fechaEvento)).toEqual([FECHAS[0]]);
  });

  test('sin pronóstico no hay resultados', () => {
    expect(evaluar(sinCultivo, [])).toEqual([]);
  });
});

describe('sequía', () => {
  const seco = { acumuladoDia: 0, precipitacionHora: 0 };
  const todoSeco = () => pronostico({ 0: seco, 1: seco, 2: seco, 3: seco, 4: seco });

  test('fuera de etapa sensible: 12 días secos → PRECAUCIÓN el día 11', () => {
    const r = evaluar(sinCultivo, todoSeco(), historial([0, 0, 0, 0, 0, 0, 0]));
    expect(r).toEqual([
      expect.objectContaining({
        nivel: 'preventiva',
        valorEsperado: 12,
        valorUmbral: 11,
        fechaEvento: FECHAS[3],
        umbralId: 'sequia_general_preventiva',
      }),
    ]);
  });

  test('más de 15 días → PELIGRO para todos; más de 10 → PELIGRO en frijol llenando', () => {
    const largo = historial(Array(11).fill(0));
    expect(evaluar(sinCultivo, todoSeco(), largo)[0]).toMatchObject({ nivel: 'critica', valorEsperado: 16 });
    const corto = historial(Array(6).fill(0));
    expect(evaluar({ cultivo: 'frijol', etapa: 'llenado' }, todoSeco(), corto)[0]).toMatchObject({
      nivel: 'critica',
      valorEsperado: 11,
      valorUmbral: 10,
      fechaEvento: FECHAS[4],
    });
  });

  test('menos de 5 días secos → nada', () => {
    expect(evaluar(sinCultivo, pronostico({ 0: seco, 1: seco, 2: seco, 3: seco }))).toEqual([]);
  });

  test('un día con lluvia corta la racha; cada racha da su propio resultado', () => {
    const r = evaluar(
      sinCultivo,
      pronostico({ 0: seco, 1: seco, 3: seco, 4: seco }),
      historial([0, 0, 0]),
    );
    // 3 del historial + 2 = 5 (lunes-martes); la racha del jueves-viernes es corta.
    expect(r).toEqual([expect.objectContaining({ nivel: 'informativa', valorEsperado: 5, fechaEvento: FECHAS[1] })]);
  });

  test('lluvia de 1 mm o más no es día seco (Zhang et al., 2011)', () => {
    const casiSeco = { acumuladoDia: 1 };
    expect(evaluar(sinCultivo, pronostico({ 0: casiSeco, 1: casiSeco, 2: casiSeco, 3: casiSeco, 4: casiSeco }))).toEqual([]);
    expect(evaluar(sinCultivo, pronostico({ 0: { acumuladoDia: 0.99 }, 1: seco, 2: seco, 3: seco, 4: seco }))).toHaveLength(1);
  });

  test('si la racha ya cumplía en el historial, conserva la fecha en que se alcanzó', () => {
    const r = evaluar(sinCultivo, pronostico({ 0: seco }), historial([0, 0, 0, 0, 0, 0]));
    // 6 días del historial (29 sep – 4 oct): llegó a 5 el sábado 3.
    expect(r).toEqual([expect.objectContaining({ nivel: 'informativa', valorEsperado: 7, fechaEvento: '20261003' })]);
  });

  test('una racha que no toca el pronóstico no se evalúa', () => {
    expect(evaluar(sinCultivo, pronostico(), historial(Array(20).fill(0)))).toEqual([]);
  });

  test('historial: se corta en un hueco, un día sin dato o con lluvia', () => {
    const conHueco = historial([0, 0, 0, 0]).filter((c) => c.fecha !== '20261002');
    expect(rachaDelHistorial(conHueco, FECHAS[0])).toEqual(['20261003', '20261004']);
    const sinDato = historial([0, 0, undefined, 0]);
    expect(rachaDelHistorial(sinDato, FECHAS[0])).toEqual(['20261004']);
    expect(rachaDelHistorial(historial([0, 3]), FECHAS[0])).toEqual([]);
    expect(rachaDelHistorial([], FECHAS[0])).toEqual([]);
  });
});

describe('catálogo vivo (RNF-19)', () => {
  test('un umbral nuevo en Firestore se usa sin tocar el código', () => {
    const nuevo = {
      umbralId: 'tmin_hortalizas_preventiva',
      tipoRiesgo: 'temperaturaBaja',
      variable: 'temperaturaMinima',
      cultivo: 'hortalizas',
      etapa: '',
      operador: 'menor',
      valor: 17,
      duracionDias: 1,
      nivel: 'preventiva',
      vigente: true,
    };
    const frio = pronostico({ 0: { temperaturaMinima: 16 } });
    const parcela = { cultivo: 'hortalizas', etapa: '' };
    expect(evaluar(parcela, frio)).toEqual([]);
    expect(evaluar(parcela, frio, [], [...catalogo, nuevo])).toEqual([
      expect.objectContaining({ nivel: 'preventiva', umbralId: 'tmin_hortalizas_preventiva' }),
    ]);
  });

  test('umbral sin tipoRiesgo: se deduce de la variable', () => {
    const { tipoRiesgo, ...sinTipo } = catalogo.find((u) => u.umbralId === 'viento_general_critica');
    expect(tipoRiesgo).toBe('vientoFuerte');
    const r = evaluar(sinCultivo, pronostico({ 0: { velocidadViento: 40 } }), [], [sinTipo]);
    expect(r).toEqual([expect.objectContaining({ tipoRiesgo: 'vientoFuerte', nivel: 'critica' })]);
  });

  test('riesgo sin regla: se anota y no detiene a los demás', () => {
    const registrar = jest.fn();
    const raro = { ...catalogo[0], umbralId: 'granizo', tipoRiesgo: 'granizo' };
    const r = evaluarParcela({
      parcela: sinCultivo,
      pronosticos: pronostico({ 0: { precipitacionHora: 20 } }),
      catalogo: [raro, ...catalogo],
      registrar,
    });
    expect(registrar).toHaveBeenCalledWith(expect.stringContaining('granizo'));
    expect(r).toEqual([expect.objectContaining({ tipoRiesgo: 'lluviaIntensa' })]);
  });

  test('un umbral no vigente no se usa', () => {
    const apagado = catalogo.map((u) => (u.umbralId === 'tmin_general_critica' ? { ...u, vigente: false } : u));
    expect(evaluar(sinCultivo, pronostico({ 0: { temperaturaMinima: -2 } }), [], apagado)).toEqual([]);
  });
});

describe('comparar', () => {
  test('operadores y valores inválidos', () => {
    expect(cumple(5, { operador: 'mayorIgual', valor: 5 })).toBe(true);
    expect(cumple(5, { operador: 'menor', valor: 5 })).toBe(false);
    expect(cumple(undefined, { operador: 'menor', valor: 5 })).toBe(false);
    expect(cumple(Number.NaN, { operador: 'mayor', valor: 0 })).toBe(false);
    expect(cumple(3, { operador: 'distinto', valor: 0 })).toBe(false);
  });

  test('a igual nivel define el umbral del cultivo', () => {
    const general = { umbralId: 'g', nivel: 'preventiva', cultivo: '' };
    const propio = { umbralId: 'c', nivel: 'preventiva', cultivo: 'cafe' };
    const informativo = { umbralId: 'i', nivel: 'informativa', cultivo: 'cafe' };
    expect(definitorio([general, propio, informativo]).umbralId).toBe('c');
    expect(definitorio([propio, general]).umbralId).toBe('c');
    expect(definitorio([])).toBeNull();
  });
});

test('diaAnterior cruza meses y años', () => {
  expect(diaAnterior('20261001')).toBe('20260930');
  expect(diaAnterior('20260101')).toBe('20251231');
  expect(diaAnterior('20240301')).toBe('20240229');
});
