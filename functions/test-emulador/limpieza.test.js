'use strict';

/**
 * Limpieza de parcelas borradas contra el emulador de Firestore.
 * Se ejecuta con:  npm run test:emulador
 */
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { limpiarParcelasBorradas } = require('../src/limpieza');

const PROYECTO = 'demo-agroclima-reglas';
let app;
let db;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('Use "npm run test:emulador" (necesita el emulador).');
  }
  app = initializeApp({ projectId: PROYECTO }, 'limpieza');
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

async function parcelaConHistorial(id) {
  const ref = db.doc(`parcelas/${id}`);
  await ref.set({ usuarioId: 'ana', nombre: id });
  await ref.collection('condiciones').doc('20261003').set({ temperatura: 20 });
  await ref.collection('pronosticos').doc('20261004').set({ tempMin: 12 });
  await db.collection('alertas').add({ parcelaId: id, usuarioId: 'ana' });
  return ref;
}

test('borra historial y alertas de la parcela borrada', async () => {
  const borrada = await parcelaConHistorial('guayabal');
  await borrada.delete(); // Lo que hace la app (solo el documento).

  const resultado = await limpiarParcelasBorradas(db);

  expect(resultado.limpiadas).toEqual(['guayabal']);
  expect((await borrada.collection('condiciones').get()).empty).toBe(true);
  expect((await borrada.collection('pronosticos').get()).empty).toBe(true);
  const alertas = await db
    .collection('alertas')
    .where('parcelaId', '==', 'guayabal')
    .get();
  expect(alertas.empty).toBe(true);
});

test('no toca las parcelas que siguen ni sus alertas', async () => {
  await parcelaConHistorial('joya');
  const borrada = await parcelaConHistorial('zapote');
  await borrada.delete();

  const resultado = await limpiarParcelasBorradas(db);

  expect(resultado.existentes).toEqual(['joya']);
  expect(resultado.limpiadas).toEqual(['zapote']);
  const joya = db.doc('parcelas/joya');
  expect((await joya.get()).exists).toBe(true);
  expect((await joya.collection('pronosticos').get()).size).toBe(1);
  const alertas = await db.collection('alertas').get();
  expect(alertas.docs.map((d) => d.data().parcelaId)).toEqual(['joya']);
});

test('una segunda vuelta no encuentra nada que limpiar', async () => {
  const borrada = await parcelaConHistorial('potrero');
  await borrada.delete();
  await limpiarParcelasBorradas(db);

  const segunda = await limpiarParcelasBorradas(db);

  expect(segunda.limpiadas).toEqual([]);
});
