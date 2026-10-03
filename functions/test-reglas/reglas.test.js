'use strict';

/**
 * Pruebas de firestore.rules con el emulador (MODELO_DATOS.md §5).
 * Se ejecutan con:  npm run test:reglas   (levanta el emulador de Firestore)
 */
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
} = require('firebase/firestore');

let entorno;

const ANA = 'ana';
const BETO = 'beto';

beforeAll(async () => {
  entorno = await initializeTestEnvironment({
    projectId: 'demo-agroclima-reglas',
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', '..', 'firestore.rules'),
        'utf8',
      ),
    },
  });
});

afterAll(async () => {
  await entorno?.cleanup();
});

beforeEach(async () => {
  await entorno.clearFirestore();
  // Datos iniciales escritos como administrador (sin reglas).
  await entorno.withSecurityRulesDisabled(async (contexto) => {
    const db = contexto.firestore();
    await setDoc(doc(db, 'usuarios', ANA), { uid: ANA, nombre: 'Ana' });
    await setDoc(doc(db, 'parcelas', 'p-ana'), {
      usuarioId: ANA,
      nombre: 'El Guayabal',
    });
    await setDoc(doc(db, 'parcelas', 'p-ana', 'pronosticos', '20260927'), {
      fecha: '20260927',
      temperaturaMinima: 12,
    });
    await setDoc(doc(db, 'alertas', 'a1'), {
      usuarioId: ANA,
      parcelaId: 'p-ana',
      mensaje: 'Va a llover fuerte el jueves.',
      leida: false,
      atendida: false,
    });
    await setDoc(doc(db, 'umbrales', 'tmin_general_critica'), { valor: 0 });
  });
});

const dbDe = (uid) => entorno.authenticatedContext(uid).firestore();
const dbAnonima = () => entorno.unauthenticatedContext().firestore();

describe('Casos obligatorios (MODELO_DATOS §5)', () => {
  test('leer parcela ajena → rechazo', async () => {
    await assertFails(getDoc(doc(dbDe(BETO), 'parcelas', 'p-ana')));
  });

  test('crear parcela con usuarioId ajeno → rechazo', async () => {
    await assertFails(
      setDoc(doc(dbDe(BETO), 'parcelas', 'p-nueva'), {
        usuarioId: ANA,
        nombre: 'Robada',
      }),
    );
  });

  test('escribir pronóstico desde el cliente → rechazo', async () => {
    await assertFails(
      setDoc(doc(dbDe(ANA), 'parcelas', 'p-ana', 'pronosticos', '20260928'), {
        fecha: '20260928',
      }),
    );
  });

  test('cambiar el mensaje de una alerta → rechazo', async () => {
    await assertFails(
      updateDoc(doc(dbDe(ANA), 'alertas', 'a1'), { mensaje: 'Otro texto' }),
    );
  });

  test('marcar como leída una alerta propia → permitido', async () => {
    await assertSucceeds(
      updateDoc(doc(dbDe(ANA), 'alertas', 'a1'), { leida: true }),
    );
  });
});

describe('Usuarios', () => {
  test('cada quien lee y crea solo su perfil', async () => {
    await assertSucceeds(getDoc(doc(dbDe(ANA), 'usuarios', ANA)));
    await assertFails(getDoc(doc(dbDe(BETO), 'usuarios', ANA)));
    await assertSucceeds(
      setDoc(doc(dbDe(BETO), 'usuarios', BETO), { uid: BETO, nombre: 'Beto' }),
    );
    await assertFails(
      setDoc(doc(dbDe(BETO), 'usuarios', 'otro'), { uid: 'otro' }),
    );
  });

  test('la cuenta no se borra desde la app', async () => {
    await assertFails(deleteDoc(doc(dbDe(ANA), 'usuarios', ANA)));
  });

  test('preferencias: solo las propias', async () => {
    await assertSucceeds(
      setDoc(doc(dbDe(ANA), 'usuarios', ANA, 'preferencias', 'sequia'), {
        tipoRiesgo: 'sequia',
        activa: true,
      }),
    );
    await assertFails(
      setDoc(doc(dbDe(BETO), 'usuarios', ANA, 'preferencias', 'sequia'), {
        activa: false,
      }),
    );
  });
});

describe('Parcelas', () => {
  test('el dueño lee, actualiza y borra su parcela', async () => {
    const db = dbDe(ANA);
    await assertSucceeds(getDoc(doc(db, 'parcelas', 'p-ana')));
    await assertSucceeds(
      updateDoc(doc(db, 'parcelas', 'p-ana'), { nombre: 'La Joya' }),
    );
    await assertSucceeds(deleteDoc(doc(db, 'parcelas', 'p-ana')));
  });

  test('otro usuario no edita ni borra mi parcela (RN-03)', async () => {
    const db = dbDe(BETO);
    await assertFails(
      updateDoc(doc(db, 'parcelas', 'p-ana'), { nombre: 'Mía' }),
    );
    await assertFails(deleteDoc(doc(db, 'parcelas', 'p-ana')));
  });

  test('no se puede traspasar una parcela a otro usuario', async () => {
    await assertFails(
      updateDoc(doc(dbDe(ANA), 'parcelas', 'p-ana'), { usuarioId: BETO }),
    );
  });

  test('condiciones: solo el dueño y solo con origen "consulta"', async () => {
    const ruta = ['parcelas', 'p-ana', 'condiciones', '20260927'];
    await assertSucceeds(
      setDoc(doc(dbDe(ANA), ...ruta), { origen: 'consulta', temperatura: 20 }),
    );
    await assertFails(
      setDoc(doc(dbDe(ANA), ...ruta), { origen: 'ciclo', temperatura: 20 }),
    );
    await assertFails(
      setDoc(doc(dbDe(BETO), ...ruta), { origen: 'consulta', temperatura: 20 }),
    );
  });

  test('pronósticos: el dueño los lee, otro no', async () => {
    const ruta = ['parcelas', 'p-ana', 'pronosticos', '20260927'];
    await assertSucceeds(getDoc(doc(dbDe(ANA), ...ruta)));
    await assertFails(getDoc(doc(dbDe(BETO), ...ruta)));
  });
});

describe('Alertas y umbrales', () => {
  test('nadie crea ni borra alertas desde la app', async () => {
    await assertFails(
      setDoc(doc(dbDe(ANA), 'alertas', 'a2'), {
        usuarioId: ANA,
        mensaje: 'falsa',
      }),
    );
    await assertFails(deleteDoc(doc(dbDe(ANA), 'alertas', 'a1')));
  });

  test('otro usuario no lee ni marca mis alertas', async () => {
    await assertFails(getDoc(doc(dbDe(BETO), 'alertas', 'a1')));
    await assertFails(
      updateDoc(doc(dbDe(BETO), 'alertas', 'a1'), { leida: true }),
    );
  });

  test('umbrales: se leen con sesión, nunca se escriben', async () => {
    await assertSucceeds(
      getDoc(doc(dbDe(ANA), 'umbrales', 'tmin_general_critica')),
    );
    await assertFails(
      getDoc(doc(dbAnonima(), 'umbrales', 'tmin_general_critica')),
    );
    await assertFails(
      setDoc(doc(dbDe(ANA), 'umbrales', 'tmin_general_critica'), { valor: 5 }),
    );
  });
});
