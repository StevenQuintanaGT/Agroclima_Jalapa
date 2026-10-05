'use strict';

/**
 * Alertas sin duplicar y avisos por FCM (HU-10) contra el emulador de
 * Firestore, con un FCM falso. Se ejecuta con:  npm run test:emulador
 */
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { generarAlertas } = require('../src/alertas');
const { enviarAvisos } = require('../src/notificaciones');

const PROYECTO = 'demo-agroclima-reglas';
// Lunes 5 de octubre de 2026: 9:00 y 23:00 en Guatemala.
const DE_DIA = new Date('2026-10-05T15:00:00Z');
const DE_NOCHE = new Date('2026-10-06T05:00:00Z');
let app;
let db;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('Use "npm run test:emulador" (necesita el emulador).');
  }
  app = initializeApp({ projectId: PROYECTO }, 'alertas');
  db = getFirestore(app);
});

afterAll(() => deleteApp(app));

beforeEach(async () => {
  await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/` +
      `${PROYECTO}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  await db.doc('usuarios/ana').set({ uid: 'ana', nombre: 'Ana', tokensFcm: ['tel-1', 'tel-viejo'] });
});

const riesgo = (datos) => ({
  parcelaId: 'joya',
  usuarioId: 'ana',
  parcelaNombre: 'La Joya',
  cultivo: 'cafe',
  tipoRiesgo: 'temperaturaBaja',
  nivel: 'preventiva',
  valorEsperado: 13,
  valorUmbral: 15,
  fechaEvento: '20261006',
  umbralId: 'tmin_cafe_preventiva',
  ...datos,
});

/** FCM falso: "tel-viejo" ya no existe; guarda los mensajes enviados. */
function fcmFalso({ caido = false } = {}) {
  const enviados = [];
  return {
    enviados,
    async sendEachForMulticast(mensaje) {
      if (caido) throw new Error('FCM no responde');
      enviados.push(mensaje);
      const responses = mensaje.tokens.map((token) =>
        token === 'tel-viejo'
          ? { success: false, error: { code: 'messaging/registration-token-not-registered' } }
          : { success: true },
      );
      return { responses, successCount: responses.filter((r) => r.success).length };
    },
  };
}

const todas = async () => (await db.collection('alertas').get()).docs.map((d) => d.data());

describe('control de duplicados (RO-03)', () => {
  test('crea la alerta con los campos de la Tabla 69', async () => {
    const [creada] = await generarAlertas({ db, riesgos: [riesgo()], ahora: DE_DIA });
    const guardada = (await db.doc(`alertas/${creada.alertaId}`).get()).data();
    expect(guardada).toMatchObject({
      alertaId: creada.alertaId,
      usuarioId: 'ana',
      parcelaId: 'joya',
      tipoRiesgo: 'temperaturaBaja',
      nivel: 'preventiva',
      valorEsperado: 13,
      valorUmbral: 15,
      mensaje: 'Mañana en la madrugada se esperan 13 °C. Proteja el almácigo.',
      leida: false,
      atendida: false,
      notificada: false,
      parcelaNombre: 'La Joya',
      cultivo: 'cafe',
    });
    expect(guardada.fechaEvento.toDate().toISOString()).toBe('2026-10-06T06:00:00.000Z');
    expect(guardada.fechaGeneracion).toBeDefined();
    expect(guardada.medidaSugerida).not.toBe('');
    expect(guardada).not.toHaveProperty('titulo');
    expect(guardada).not.toHaveProperty('umbralId');
  });

  test('la vuelta siguiente con el mismo evento no duplica', async () => {
    await generarAlertas({ db, riesgos: [riesgo()], ahora: DE_DIA });
    const segunda = await generarAlertas({ db, riesgos: [riesgo({ valorEsperado: 12.5 })], ahora: DE_DIA });
    expect(segunda).toEqual([]);
    expect(await todas()).toHaveLength(1);
  });

  test('si el riesgo empeora se crea otra; si baja, nada', async () => {
    await generarAlertas({ db, riesgos: [riesgo()], ahora: DE_DIA });
    const peor = await generarAlertas({
      db,
      riesgos: [riesgo({ nivel: 'critica', valorEsperado: -1, valorUmbral: 0 })],
      ahora: DE_DIA,
    });
    expect(peor).toHaveLength(1);
    expect(await generarAlertas({ db, riesgos: [riesgo()], ahora: DE_DIA })).toEqual([]);
    expect((await todas()).map((a) => a.nivel).sort()).toEqual(['critica', 'preventiva']);
  });

  test('otro día, otro riesgo u otra parcela no cuentan como duplicado', async () => {
    await generarAlertas({ db, riesgos: [riesgo()], ahora: DE_DIA });
    const nuevas = await generarAlertas({
      db,
      riesgos: [
        riesgo({ fechaEvento: '20261007' }),
        riesgo({ tipoRiesgo: 'humedadAlta', valorEsperado: 90, valorUmbral: 85 }),
        riesgo({ parcelaId: 'otra' }),
      ],
      ahora: DE_DIA,
    });
    expect(nuevas).toHaveLength(3);
  });
});

describe('avisos por FCM (UMBRALES.md §6)', () => {
  test('envía al dueño con su canal, quita el token viejo y marca notificada', async () => {
    const alertas = await generarAlertas({ db, riesgos: [riesgo({ nivel: 'critica', valorEsperado: -1, valorUmbral: 0 })], ahora: DE_DIA });
    const fcm = fcmFalso();
    const resumen = await enviarAvisos({ db, mensajeria: fcm, alertas, ahora: DE_DIA, registrar: () => {} });

    expect(resumen).toEqual({ enviadas: 1, sinAviso: 0, fallidas: 0, tokensQuitados: 1 });
    expect(fcm.enviados).toHaveLength(1);
    expect(fcm.enviados[0]).toMatchObject({
      tokens: ['tel-1', 'tel-viejo'],
      notification: {
        title: 'PELIGRO: puede caer helada en La Joya',
        body: 'Mañana en la madrugada puede bajar a -1 °C. Proteja el almácigo.',
      },
      data: { alertaId: alertas[0].alertaId, parcelaId: 'joya', nivel: 'critica' },
      android: { priority: 'high', notification: { channelId: 'alertas_peligro' } },
    });
    expect((await db.doc('usuarios/ana').get()).get('tokensFcm')).toEqual(['tel-1']);
    expect((await db.doc(`alertas/${alertas[0].alertaId}`).get()).get('notificada')).toBe(true);
  });

  test('tipo apagado: no suena pero la alerta queda en la app', async () => {
    await db.doc('usuarios/ana/preferencias/temperaturaBaja').set({ tipoRiesgo: 'temperaturaBaja', activa: false });
    const alertas = await generarAlertas({ db, riesgos: [riesgo()], ahora: DE_DIA });
    const fcm = fcmFalso();
    const resumen = await enviarAvisos({ db, mensajeria: fcm, alertas, ahora: DE_DIA, registrar: () => {} });
    expect(resumen.sinAviso).toBe(1);
    expect(fcm.enviados).toEqual([]);
    expect(await todas()).toEqual([expect.objectContaining({ notificada: false })]);
  });

  test('de noche solo suena PELIGRO', async () => {
    const alertas = await generarAlertas({
      db,
      riesgos: [
        riesgo(),
        riesgo({ tipoRiesgo: 'vientoFuerte', nivel: 'critica', valorEsperado: 35, valorUmbral: 30 }),
      ],
      ahora: DE_NOCHE,
    });
    const fcm = fcmFalso();
    await enviarAvisos({ db, mensajeria: fcm, alertas, ahora: DE_NOCHE, registrar: () => {} });
    expect(fcm.enviados.map((m) => m.data.nivel)).toEqual(['critica']);
  });

  test('tres días de calor: una sola notificación, las tres alertas notificadas', async () => {
    const calor = (fechaEvento) =>
      riesgo({ tipoRiesgo: 'temperaturaAlta', nivel: 'critica', valorEsperado: 31, valorUmbral: 30, fechaEvento, diasConsecutivos: 3 });
    const alertas = await generarAlertas({
      db,
      riesgos: [calor('20261006'), calor('20261007'), calor('20261008')],
      ahora: DE_DIA,
    });
    const fcm = fcmFalso();
    await enviarAvisos({ db, mensajeria: fcm, alertas, ahora: DE_DIA, registrar: () => {} });
    expect(fcm.enviados).toHaveLength(1);
    expect(fcm.enviados[0].notification.body).toBe(
      'Desde mañana, 3 días seguidos con más de 30 °C. Dé sombra y riegue si puede.',
    );
    expect((await todas()).every((a) => a.notificada)).toBe(true);
  });

  test('FCM caído o sin teléfonos: la alerta queda en la app sin notificar (RT-05)', async () => {
    const alertas = await generarAlertas({ db, riesgos: [riesgo()], ahora: DE_DIA });
    const resumen = await enviarAvisos({
      db,
      mensajeria: fcmFalso({ caido: true }),
      alertas,
      ahora: DE_DIA,
      registrar: () => {},
    });
    expect(resumen.fallidas).toBe(1);
    await db.doc('usuarios/ana').update({ tokensFcm: [] });
    const sinTelefono = await enviarAvisos({ db, mensajeria: fcmFalso(), alertas, ahora: DE_DIA, registrar: () => {} });
    expect(sinTelefono.sinAviso).toBe(1);
    expect(await todas()).toEqual([expect.objectContaining({ notificada: false })]);
  });

  test('solo avisa al dueño de la parcela', async () => {
    await db.doc('usuarios/beto').set({ uid: 'beto', tokensFcm: ['tel-beto'] });
    const alertas = await generarAlertas({ db, riesgos: [riesgo()], ahora: DE_DIA });
    const fcm = fcmFalso();
    await enviarAvisos({ db, mensajeria: fcm, alertas, ahora: DE_DIA, registrar: () => {} });
    expect(fcm.enviados.flatMap((m) => m.tokens)).not.toContain('tel-beto');
  });
});
