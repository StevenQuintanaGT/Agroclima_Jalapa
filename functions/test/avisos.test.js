'use strict';

const { textosAlerta, cuando, MEDIDAS } = require('../src/mensajes');
const { enSilencio, debeAvisar, agruparSeguidas } = require('../src/notificaciones');
const { inicioDelDia, horaLocal, diaDeSemana } = require('../src/fechas');
const { TIPOS_RIESGO } = require('../src/config');

// Lunes 5 de octubre de 2026, 9:00 en Guatemala.
const AHORA = new Date('2026-10-05T15:00:00Z');
const riesgo = (datos) => ({
  parcelaNombre: 'La Joya',
  cultivo: '',
  fechaEvento: '20261006',
  valorUmbral: 0,
  ...datos,
});

describe('mensajes (RNF-14, pantalla 24)', () => {
  test('helada: título con la palabra del semáforo y la parcela', () => {
    const t = textosAlerta(
      riesgo({ tipoRiesgo: 'temperaturaBaja', nivel: 'critica', valorEsperado: -1.3, valorUmbral: 0, cultivo: 'cafe' }),
      AHORA,
    );
    expect(t.titulo).toBe('PELIGRO: puede caer helada en La Joya');
    expect(t.mensaje).toBe('Mañana en la madrugada puede bajar a -1 °C. Proteja el almácigo.');
    expect(t.medidaSugerida).toContain('almácigo');
  });

  test('viento de hoy, como en el diseño', () => {
    const t = textosAlerta(
      riesgo({ tipoRiesgo: 'vientoFuerte', nivel: 'preventiva', valorEsperado: 32.4, fechaEvento: '20261005', parcelaNombre: 'El Guayabal' }),
      AHORA,
    );
    expect(t.titulo).toBe('PRECAUCIÓN: viento fuerte en El Guayabal');
    expect(t.mensaje).toBe('Hoy, viento de hasta 32 km/h. No fumigue.');
  });

  test('cada día de una ola de calor dice desde cuándo empieza', () => {
    const t = textosAlerta(
      riesgo({ tipoRiesgo: 'temperaturaAlta', nivel: 'critica', valorEsperado: 31, valorUmbral: 30, fechaEvento: '20261008', inicioRacha: '20261006', diasConsecutivos: 3 }),
      AHORA,
    );
    expect(t.mensaje).toBe('Desde mañana, 3 días seguidos con más de 30 °C. Riegue si puede.');
  });

  test('calor de varios días y sequía cuentan los días', () => {
    const calor = textosAlerta(
      riesgo({ tipoRiesgo: 'temperaturaAlta', nivel: 'critica', valorEsperado: 31, valorUmbral: 30, fechaEvento: '20261007', diasConsecutivos: 3, cultivo: 'cafe' }),
      AHORA,
    );
    expect(calor.mensaje).toBe('Desde el miércoles, 3 días seguidos con más de 30 °C. Dé sombra y riegue si puede.');
    const sequia = textosAlerta(
      riesgo({ tipoRiesgo: 'sequia', nivel: 'preventiva', valorEsperado: 7, valorUmbral: 5, diasConsecutivos: 7, cultivo: 'maiz' }),
      AHORA,
    );
    expect(sequia.titulo).toBe('PRECAUCIÓN: días sin lluvia en La Joya');
    expect(sequia.mensaje).toBe('Se esperan 7 días seguidos sin lluvia. Si puede, riegue el maíz.');
  });

  test('frío que no es helada, lluvia y humedad', () => {
    expect(
      textosAlerta(riesgo({ tipoRiesgo: 'temperaturaBaja', nivel: 'preventiva', valorEsperado: 17, valorUmbral: 18, cultivo: 'frijol' }), AHORA).titulo,
    ).toBe('PRECAUCIÓN: frío en La Joya');
    expect(
      textosAlerta(riesgo({ tipoRiesgo: 'lluviaIntensa', nivel: 'critica', valorEsperado: 31.6, fechaEvento: '20261008' }), AHORA).mensaje,
    ).toBe('El jueves se esperan hasta 32 mm de lluvia por hora. Revise que el agua pueda salir de la parcela.');
    expect(
      textosAlerta(riesgo({ tipoRiesgo: 'humedadAlta', nivel: 'preventiva', valorEsperado: 90, cultivo: 'cafe' }), AHORA).mensaje,
    ).toBe('Mañana la humedad llegará a 90 %. Esté pendiente de hongos en las hojas.');
  });

  test('cada tipo de riesgo tiene qué hacer en general', () => {
    for (const tipo of TIPOS_RIESGO) {
      expect(MEDIDAS[tipo][''].corta).toBeTruthy();
      expect(MEDIDAS[tipo][''].larga).toBeTruthy();
    }
  });

  test('cuándo: hoy, mañana o el día de la semana; un día pasado es hoy', () => {
    expect(cuando('20261005', AHORA)).toBe('hoy');
    expect(cuando('20261003', AHORA)).toBe('hoy');
    expect(cuando('20261006', AHORA)).toBe('mañana');
    expect(cuando('20261009', AHORA)).toBe('el viernes');
    // A las 11 p.m. del lunes en Guatemala ya es martes en UTC.
    expect(cuando('20261006', new Date('2026-10-06T05:00:00Z'))).toBe('mañana');
  });

  test('sin palabras técnicas ni en inglés', () => {
    for (const tipo of TIPOS_RIESGO) {
      const t = textosAlerta(riesgo({ tipoRiesgo: tipo, nivel: 'preventiva', valorEsperado: 20 }), AHORA);
      expect(`${t.titulo} ${t.mensaje}`).not.toMatch(/umbral|tipoRiesgo|undefined|NaN|null/i);
    }
  });
});

describe('preferencias y silencio (UMBRALES.md §6)', () => {
  test('silencio que cruza la medianoche', () => {
    expect(enSilencio('23:10', '22:00', '05:00')).toBe(true);
    expect(enSilencio('04:59', '22:00', '05:00')).toBe(true);
    expect(enSilencio('05:00', '22:00', '05:00')).toBe(false);
    expect(enSilencio('12:00', '22:00', '05:00')).toBe(false);
    expect(enSilencio('13:00', '12:00', '14:00')).toBe(true);
    expect(enSilencio('13:00', '12:00', '12:00')).toBe(false);
    expect(enSilencio('13:00', undefined, '05:00')).toBe(false);
  });

  const alerta = (nivel) => ({ nivel });
  test('tipo apagado no suena, ni siquiera PELIGRO', () => {
    expect(debeAvisar(alerta('critica'), { activa: false }, '12:00')).toBe(false);
  });

  test('nivel mínimo: "solo peligro" deja fuera PRECAUCIÓN', () => {
    expect(debeAvisar(alerta('preventiva'), { nivelMinimo: 'critica' }, '12:00')).toBe(false);
    expect(debeAvisar(alerta('critica'), { nivelMinimo: 'critica' }, '12:00')).toBe(true);
    // Por defecto desde PRECAUCIÓN: NORMAL no suena.
    expect(debeAvisar(alerta('informativa'), undefined, '12:00')).toBe(false);
    expect(debeAvisar(alerta('preventiva'), undefined, '12:00')).toBe(true);
  });

  test('en horario de silencio solo suena PELIGRO', () => {
    expect(debeAvisar(alerta('preventiva'), undefined, '23:00')).toBe(false);
    expect(debeAvisar(alerta('critica'), undefined, '23:00')).toBe(true);
    expect(debeAvisar(alerta('preventiva'), { silencioDesde: '00:00', silencioHasta: '00:00' }, '23:00')).toBe(true);
  });
});

test('agrupa días seguidos del mismo riesgo, nivel y parcela', () => {
  const a = (parcelaId, tipoRiesgo, nivel, fechaEventoId) => ({ parcelaId, tipoRiesgo, nivel, fechaEventoId });
  const grupos = agruparSeguidas([
    a('p1', 'temperaturaAlta', 'critica', '20261008'),
    a('p1', 'temperaturaAlta', 'critica', '20261006'),
    a('p1', 'temperaturaAlta', 'critica', '20261007'),
    a('p1', 'vientoFuerte', 'preventiva', '20261005'),
    a('p1', 'vientoFuerte', 'preventiva', '20261007'),
    a('p2', 'temperaturaAlta', 'critica', '20261006'),
    a('p1', 'lluviaIntensa', 'preventiva', '20261005'),
    a('p1', 'lluviaIntensa', 'critica', '20261006'),
  ]);
  expect(grupos.map((g) => g.map((x) => `${x.parcelaId}:${x.tipoRiesgo}:${x.fechaEventoId}`))).toEqual([
    ['p1:lluviaIntensa:20261006'],
    ['p1:lluviaIntensa:20261005'],
    ['p1:temperaturaAlta:20261006', 'p1:temperaturaAlta:20261007', 'p1:temperaturaAlta:20261008'],
    ['p1:vientoFuerte:20261005'],
    ['p1:vientoFuerte:20261007'],
    ['p2:temperaturaAlta:20261006'],
  ]);
});

test('fechas: inicio del día, hora local y día de la semana', () => {
  expect(inicioDelDia('20261005').toISOString()).toBe('2026-10-05T06:00:00.000Z');
  expect(horaLocal(new Date('2026-10-06T04:30:00Z'))).toBe('22:30');
  expect(diaDeSemana('20261005')).toBe(1);
});
