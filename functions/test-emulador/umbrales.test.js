'use strict';

/**
 * Catálogo de umbrales en Firestore (RNF-19): lo que se cambia en la base se
 * usa en la siguiente vuelta, sin tocar el código.  npm run test:emulador
 */
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { leerCatalogo, aplicables } = require('../src/umbrales');

const PROYECTO = 'demo-agroclima-reglas';
let app;
let db;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('Use "npm run test:emulador" (necesita el emulador).');
  }
  app = initializeApp({ projectId: PROYECTO }, 'umbrales');
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

const lluvia = {
  tipoRiesgo: 'lluviaIntensa',
  variable: 'precipitacionHora',
  cultivo: '',
  etapa: '',
  operador: 'mayor',
  valor: 15,
  duracionDias: 1,
  nivel: 'preventiva',
  fuente: 'Monjo (2010)',
  vigente: true,
};

test('un umbral nuevo en Firestore se usa sin cambiar el código', async () => {
  await db.doc('umbrales/lluvia_general_preventiva').set(lluvia);
  expect((await leerCatalogo(db)).map((u) => u.umbralId)).toEqual(['lluvia_general_preventiva']);

  await db.doc('umbrales/humedad_maiz_preventiva').set({
    ...lluvia,
    tipoRiesgo: 'humedadAlta',
    variable: 'humedadRelativa',
    cultivo: 'maiz',
    valor: 90,
  });

  const catalogo = await leerCatalogo(db);
  expect(aplicables(catalogo, { cultivo: 'maiz', etapa: 'floracion' })).toHaveLength(2);
  expect(aplicables(catalogo, { cultivo: 'cafe' })).toHaveLength(1);
});

test('los no vigentes y los mal escritos se ignoran sin detener el ciclo', async () => {
  const avisos = [];
  await db.doc('umbrales/apagado').set({ ...lluvia, vigente: false });
  await db.doc('umbrales/roto').set({ ...lluvia, operador: 'muchoMas' });
  await db.doc('umbrales/bueno').set(lluvia);

  const catalogo = await leerCatalogo(db, (m) => avisos.push(m));

  expect(catalogo.map((u) => u.umbralId)).toEqual(['bueno']);
  expect(avisos).toEqual([expect.stringContaining('roto')]);
});
