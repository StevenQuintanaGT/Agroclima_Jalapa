'use strict';

/**
 * Eliminación de cuentas contra el emulador de Firestore, con un Auth falso.
 * Se ejecuta con:  npm run test:emulador
 */
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { eliminarCuentasSolicitadas } = require('../src/cuentas');

const PROYECTO = 'demo-agroclima-reglas';
let app;
let db;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('Use "npm run test:emulador" (necesita el emulador).');
  }
  app = initializeApp({ projectId: PROYECTO }, 'cuentas');
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

/** Auth falso que recuerda a quién borró. */
function authFalso({ falla } = {}) {
  const borrados = [];
  return {
    borrados,
    async deleteUser(uid) {
      if (falla) throw Object.assign(new Error(falla), { code: falla });
      borrados.push(uid);
    },
  };
}

async function cuenta(uid, { pidioEliminar }) {
  const perfil = db.doc(`usuarios/${uid}`);
  await perfil.set({
    uid,
    nombre: uid,
    tokensFcm: [],
    ...(pidioEliminar ? { eliminacionSolicitada: FieldValue.serverTimestamp() } : {}),
  });
  await perfil.collection('preferencias').doc('temperaturaBaja').set({ activa: true });
  const parcela = db.doc(`parcelas/${uid}-parcela`);
  await parcela.set({ usuarioId: uid, nombre: 'La Joya' });
  await parcela.collection('condiciones').doc('20261010').set({ temperatura: 18 });
  await parcela.collection('pronosticos').doc('20261011').set({ tempMin: 9 });
  await db.collection('alertas').add({ usuarioId: uid, parcelaId: parcela.id });
  // Alerta de una parcela que ya borró antes.
  await db.collection('alertas').add({ usuarioId: uid, parcelaId: 'vieja' });
  const encuesta = db.doc(`encuestas/${uid}`);
  await encuesta.set({ uid, p1: 'facil', consentimiento: true });
  return { perfil, parcela, encuesta };
}

test('borra el acceso, el perfil, las preferencias, las parcelas, las alertas y la encuesta', async () => {
  const { perfil, parcela, encuesta } = await cuenta('ana', { pidioEliminar: true });
  const auth = authFalso();

  const eliminadas = await eliminarCuentasSolicitadas(db, auth);

  expect(eliminadas).toEqual(['ana']);
  expect(auth.borrados).toEqual(['ana']);
  expect((await perfil.get()).exists).toBe(false);
  expect((await perfil.collection('preferencias').get()).empty).toBe(true);
  expect((await parcela.get()).exists).toBe(false);
  expect((await parcela.collection('condiciones').get()).empty).toBe(true);
  expect((await parcela.collection('pronosticos').get()).empty).toBe(true);
  expect((await db.collection('alertas').get()).empty).toBe(true);
  expect((await encuesta.get()).exists).toBe(false);
});

test('no toca a quien no lo pidió', async () => {
  await cuenta('ana', { pidioEliminar: true });
  const { perfil, parcela, encuesta } = await cuenta('beto', { pidioEliminar: false });
  const auth = authFalso();

  await eliminarCuentasSolicitadas(db, auth);

  expect(auth.borrados).toEqual(['ana']);
  expect((await perfil.get()).exists).toBe(true);
  expect((await parcela.collection('condiciones').get()).size).toBe(1);
  expect((await encuesta.get()).exists).toBe(true);
  const alertas = await db.collection('alertas').get();
  expect(alertas.docs.map((d) => d.data().usuarioId)).toEqual(['beto', 'beto']);
});

test('si el acceso ya no existía, igual borra los datos', async () => {
  const { perfil } = await cuenta('ana', { pidioEliminar: true });

  await eliminarCuentasSolicitadas(db, authFalso({ falla: 'auth/user-not-found' }));

  expect((await perfil.get()).exists).toBe(false);
});

test('si Auth falla, no borra nada, no detiene el ciclo y la próxima vuelta lo reintenta', async () => {
  const { perfil, parcela } = await cuenta('ana', { pidioEliminar: true });

  const registro = [];
  const eliminadas = await eliminarCuentasSolicitadas(
    db,
    authFalso({ falla: 'auth/internal-error' }),
    (texto) => registro.push(texto),
  );

  expect(eliminadas).toEqual([]);
  expect(registro).toHaveLength(1);
  expect((await perfil.get()).exists).toBe(true);
  expect((await parcela.get()).exists).toBe(true);
  const auth = authFalso();
  expect(await eliminarCuentasSolicitadas(db, auth)).toEqual(['ana']);
});
