'use strict';

/**
 * Ciclo completo (adquisición → motor) contra el emulador de Firestore, con
 * un OpenWeather falso. Se ejecuta con:  npm run test:emulador
 */
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { ejecutarCiclo } = require('../index');
const catalogoSemilla = require('../seed/umbrales.json');

const PROYECTO = 'demo-agroclima-reglas';
const CELDA = '14.65_-90.00';
const CELDA_CAIDA = '14.50_-89.80';
// Lunes 5 de octubre de 2026, 9:00 en Guatemala.
const AHORA = new Date('2026-10-05T15:00:00Z');
const HORA_MS = 3600 * 1000;
let app;
let db;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('Use "npm run test:emulador" (necesita el emulador).');
  }
  app = initializeApp({ projectId: PROYECTO }, 'evaluacion');
  db = getFirestore(app);
});

afterAll(() => deleteApp(app));

beforeEach(async () => {
  await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/` +
      `${PROYECTO}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  const lote = db.batch();
  for (const umbral of catalogoSemilla) lote.set(db.doc(`umbrales/${umbral.umbralId}`), umbral);
  await lote.commit();
});

async function parcela(id, datos) {
  await db.doc(`parcelas/${id}`).set({
    usuarioId: 'ana',
    nombre: id,
    activa: true,
    celdaClima: CELDA,
    cultivo: '',
    etapa: '',
    fechaRegistro: Timestamp.fromDate(new Date('2026-09-01T12:00:00Z')),
    ...datos,
  });
}

/** Día local (Guatemala) de un instante, como yyyyMMdd. */
const diaLocal = (instante) =>
  new Date(instante.getTime() - 6 * HORA_MS).toISOString().slice(0, 10).replaceAll('-', '');

/** OpenWeather falso: sin lluvia; martes a jueves con 31 °C de máxima. */
function climaFalso() {
  const calor = new Set(['20261006', '20261007', '20261008']);
  return {
    actual: async (lat) => {
      if (lat === 14.5) throw Object.assign(new Error('caído'), { motivo: 'servicioCaido' });
      return {
        fechaHora: new Date(AHORA.getTime() - 10 * 60 * 1000),
        temperatura: 22,
        sensacionTermica: 22,
        humedadRelativa: 65,
        lluviaUltimaHora: 0,
        velocidadViento: 6,
        codigoClima: 800,
      };
    },
    pronostico: async () =>
      Array.from({ length: 40 }, (_, i) => {
        const fechaHora = new Date(Date.UTC(2026, 9, 5, 18) + i * 3 * HORA_MS);
        const maxima = calor.has(diaLocal(fechaHora)) ? 31 : 25;
        return {
          fechaHora,
          temperatura: 22,
          temperaturaMinima: 19,
          temperaturaMaxima: maxima,
          humedadRelativa: 70,
          lluvia3h: 0,
          velocidadViento: 8,
          probabilidadLluvia: 0,
          codigoClima: 800,
        };
      }),
  };
}

test('evalúa las celdas actualizadas con el catálogo de Firestore y el historial', async () => {
  await parcela('cafetal', { cultivo: 'cafe', etapa: 'floracion' });
  await parcela('potrero', {
    fechaRegistro: Timestamp.fromDate(new Date('2026-10-04T12:00:00Z')),
  });
  await parcela('lejana', { celdaClima: CELDA_CAIDA, cultivo: 'cafe' });
  // Historial de la parcela más vieja de la celda: 4 días secos tras uno lluvioso.
  const lluvias = { 20260930: 8, 20261001: 0, 20261002: 0.3, 20261003: 0, 20261004: 0 };
  for (const [fecha, precipitacion] of Object.entries(lluvias)) {
    await db.doc(`parcelas/cafetal/condiciones/${fecha}`).set({ fecha, precipitacion });
  }

  const registro = [];
  const { evaluacion } = await ejecutarCiclo({
    db,
    clima: climaFalso(),
    ahora: AHORA,
    registrar: (m) => registro.push(m),
  });

  expect(evaluacion.parcelas).toBe(2);
  const resumen = evaluacion.riesgos.map((r) => [r.parcelaId, r.tipoRiesgo, r.fechaEvento, r.nivel]);
  expect(resumen).toEqual(
    expect.arrayContaining([
      // 4 del historial + hoy (sin lluvia) = 5 → NORMAL para las dos parcelas.
      ['cafetal', 'sequia', '20261005', 'informativa'],
      ['potrero', 'sequia', '20261005', 'informativa'],
      ['cafetal', 'temperaturaAlta', '20261006', 'critica'],
      ['cafetal', 'temperaturaAlta', '20261007', 'critica'],
      ['cafetal', 'temperaturaAlta', '20261008', 'critica'],
    ]),
  );
  expect(resumen).toHaveLength(5);
  expect(evaluacion.riesgos.find((r) => r.parcelaId === 'cafetal' && r.tipoRiesgo === 'sequia')).toMatchObject({
    usuarioId: 'ana',
    parcelaNombre: 'cafetal',
    cultivo: 'cafe',
    valorEsperado: 9,
    diasConsecutivos: 9,
  });
  // La celda sin clima no se evalúa (§4.7.2).
  expect(evaluacion.riesgos.some((r) => r.parcelaId === 'lejana')).toBe(false);
  expect(registro).toContain('Motor: 2 parcelas evaluadas, 5 riesgos.');
}, 20000);

test('un umbral cambiado en Firestore se usa en la vuelta siguiente (RNF-19)', async () => {
  await parcela('cafetal', { cultivo: 'cafe' });
  await db.doc('umbrales/tmax_cafe_critica').update({ vigente: false });
  await db.doc('umbrales/tmax_cafe_preventiva').update({ valor: 32 });

  const { evaluacion } = await ejecutarCiclo({ db, clima: climaFalso(), ahora: AHORA, registrar: () => {} });
  expect(evaluacion.riesgos.filter((r) => r.tipoRiesgo === 'temperaturaAlta')).toEqual([]);
}, 20000);

test('sin catálogo no se evalúa y se avisa en el registro', async () => {
  await parcela('cafetal', { cultivo: 'cafe' });
  const umbrales = await db.collection('umbrales').listDocuments();
  await Promise.all(umbrales.map((ref) => ref.delete()));

  const registro = [];
  const { evaluacion } = await ejecutarCiclo({
    db,
    clima: climaFalso(),
    ahora: AHORA,
    registrar: (m) => registro.push(m),
  });
  expect(evaluacion.riesgos).toEqual([]);
  expect(registro.join('\n')).toContain('catálogo de umbrales está vacío');
}, 20000);
