'use strict';

/**
 * Adquisición del clima contra el emulador de Firestore, con un cliente de
 * clima falso. Se ejecuta con:  npm run test:emulador
 */
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { adquirirClima, centroDeCelda } = require('../src/adquisicion');
const { ErrorClima } = require('../src/openweather');

const PROYECTO = 'demo-agroclima-reglas';
let app;
let db;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('Use "npm run test:emulador" (necesita el emulador).');
  }
  app = initializeApp({ projectId: PROYECTO }, 'adquisicion');
  db = getFirestore(app);
});

afterAll(() => deleteApp(app));

beforeEach(async () => {
  await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/` +
      `${PROYECTO}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
});

/** Hora de Guatemala del 3 de octubre de 2026 (UTC-6). */
const gt = (hora, dia = 3) => new Date(Date.UTC(2026, 9, dia, 6 + hora));

/** 40 franjas desde [desde], con [lluvia] mm cada una. */
function franjasDesde(desde, lluvia = 0) {
  return Array.from({ length: 40 }, (_, i) => ({
    fechaHora: new Date(desde.getTime() + i * 3 * 3600 * 1000),
    temperatura: 20,
    temperaturaMinima: 14,
    temperaturaMaxima: 26,
    humedadRelativa: 80,
    lluvia3h: lluvia,
    velocidadViento: 12,
    probabilidadLluvia: 0.5,
    codigoClima: 500,
    descripcion: '',
  }));
}

function climaFalso({ observado, desde, lluvia = 0, fallan = [] }) {
  const pedidas = [];
  return {
    pedidas,
    async actual(lat, lon) {
      pedidas.push(`actual ${lat}_${lon}`);
      if (fallan.includes(`${lat}_${lon}`)) throw new ErrorClima('servicioCaido');
      return {
        fechaHora: observado,
        temperatura: 23.4,
        humedadRelativa: 71,
        velocidadViento: 9.5,
        lluviaUltimaHora: 0,
      };
    },
    async pronostico(lat, lon) {
      pedidas.push(`pronostico ${lat}_${lon}`);
      return franjasDesde(desde, lluvia);
    },
  };
}

async function parcela(id, celda, extra = {}) {
  await db.doc(`parcelas/${id}`).set({ usuarioId: 'ana', celdaClima: celda, activa: true, ...extra });
}

const sinPausa = async () => {};
const callado = () => {};

test('consulta una vez por celda y escribe en todas sus parcelas', async () => {
  await parcela('guayabal', '14.65_-90.00');
  await parcela('vecina', '14.65_-90.00');
  await parcela('monjas', '14.50_-89.85');
  await parcela('dormida', '14.50_-89.85', { activa: false });
  const clima = climaFalso({ observado: gt(12), desde: gt(12) });

  const resumen = await adquirirClima({
    db,
    clima,
    ahora: gt(12, 3),
    esperar: sinPausa,
    registrar: callado,
  });

  expect(resumen).toMatchObject({ celdas: 2, llamadas: 4, parcelas: 3, fallidas: [] });
  expect(clima.pedidas.sort()).toEqual([
    'actual 14.5_-89.85',
    'actual 14.65_-90',
    'pronostico 14.5_-89.85',
    'pronostico 14.65_-90',
  ]);

  const condicion = (await db.doc('parcelas/vecina/condiciones/20261003').get()).data();
  expect(condicion).toMatchObject({
    fecha: '20261003',
    temperatura: 23.4,
    humedadRelativa: 71,
    velocidadViento: 9.5,
    precipitacion: 0,
    origen: 'ciclo',
    vigente: true,
  });
  expect(condicion.fechaHora.toDate()).toEqual(gt(12));

  const pronosticos = await db.collection('parcelas/guayabal/pronosticos').get();
  expect(pronosticos.docs.map((d) => d.id)).toEqual([
    '20261003',
    '20261004',
    '20261005',
    '20261006',
    '20261007',
  ]);
  expect(pronosticos.docs[1].data()).toMatchObject({
    temperaturaMinima: 14,
    temperaturaMaxima: 26,
    velocidadViento: 12,
    humedadRelativa: 80,
  });
  expect(pronosticos.docs[1].get('fechaConsulta')).toBeDefined();
  expect((await db.collection('parcelas/dormida/pronosticos').get()).empty).toBe(true);
});

test('si una celda falla, sigue con las demás y no toca la fallida', async () => {
  await parcela('guayabal', '14.65_-90.00');
  await parcela('monjas', '14.50_-89.85');
  const clima = climaFalso({ observado: gt(12), desde: gt(12), fallan: ['14.5_-89.85'] });

  const resumen = await adquirirClima({ db, clima, ahora: gt(12), esperar: sinPausa, registrar: callado });

  expect(resumen.fallidas).toEqual([{ celda: '14.50_-89.85', motivo: 'servicioCaido' }]);
  expect(resumen.actualizadas).toEqual(['guayabal']);
  expect((await db.collection('parcelas/monjas/condiciones').get()).empty).toBe(true);
});

test('la lluvia del día suma lo que ya pasó, también al cruzar la medianoche', async () => {
  await parcela('guayabal', '14.65_-90.00');
  const vuelta = (hora, dia, lluvia) =>
    adquirirClima({
      db,
      clima: climaFalso({ observado: gt(hora, dia), desde: gt(hora, dia), lluvia }),
      ahora: gt(hora, dia),
      esperar: sinPausa,
      registrar: callado,
    });

  await vuelta(15, 3, 2); // prevé 15–18 y 18–21 y 21–24 con 2 mm cada una
  await vuelta(21, 3, 0); // ya pasaron 15–18 y 18–21 → 4 mm; 21–24 ahora sin lluvia
  let hoy = (await db.doc('parcelas/guayabal/condiciones/20261003').get()).data();
  expect(hoy.precipitacion).toBe(4);

  await vuelta(0, 4, 0); // medianoche: se cierra 21–24 del día 3 (0 mm)
  hoy = (await db.doc('parcelas/guayabal/condiciones/20261003').get()).data();
  expect(hoy.precipitacion).toBe(4);
  expect(hoy.lluviaPrevista).toEqual({});
  const manana = (await db.doc('parcelas/guayabal/condiciones/20261004').get()).data();
  expect(manana.precipitacion).toBe(0);
});

test('una observación vieja no reemplaza a la guardada (VA-08)', async () => {
  await parcela('guayabal', '14.65_-90.00');
  await adquirirClima({
    db,
    clima: climaFalso({ observado: gt(12), desde: gt(12) }),
    ahora: gt(12),
    esperar: sinPausa,
    registrar: callado,
  });
  const vieja = climaFalso({ observado: gt(9), desde: gt(15) });
  vieja.actual = async () => ({
    fechaHora: gt(9),
    temperatura: 5,
    humedadRelativa: 10,
    velocidadViento: 1,
  });

  await adquirirClima({ db, clima: vieja, ahora: gt(15), esperar: sinPausa, registrar: callado });

  const condicion = (await db.doc('parcelas/guayabal/condiciones/20261003').get()).data();
  expect(condicion.temperatura).toBe(23.4);
  expect(condicion.fechaHora.toDate()).toEqual(gt(12));
});

test('el centro de la celda sale de su id', () => {
  expect(centroDeCelda('14.65_-90.00')).toEqual({ lat: 14.65, lon: -90 });
  expect(centroDeCelda('x')).toBeNull();
});
