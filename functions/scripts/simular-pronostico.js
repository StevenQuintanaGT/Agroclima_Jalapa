'use strict';

/**
 * SOLO EMULADOR (plans/04 "Cómo probar sin esperar el clima real"). Escribe
 * un pronóstico extremo para una parcela y corre el motor y el generador de
 * alertas, sin avisar por FCM (el emulador no tiene FCM).
 *
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node scripts/simular-pronostico.js <parcelaId> <escenario>
 *
 * Escenarios: helada, frio, calor, lluvia, viento, humedad, sequia.
 * Nunca se ejecuta contra producción: sin el emulador, se niega.
 */
const { FieldValue } = require('firebase-admin/firestore');
const { idDiario } = require('../src/fechas');
const { leerCatalogo } = require('../src/umbrales');
const { evaluarCeldas } = require('../src/evaluacion');
const { generarAlertas } = require('../src/alertas');

const ESCENARIOS = {
  helada: { temperaturaMinima: -1 },
  frio: { temperaturaMinima: 13 },
  calor: { temperaturaMaxima: 33 },
  lluvia: { precipitacionHora: 22, acumuladoDia: 40 },
  viento: { velocidadViento: 34 },
  humedad: { humedadRelativa: 92 },
  sequia: { acumuladoDia: 0, precipitacionHora: 0 },
};

function pronosticoSimulado(ahora, cambios) {
  return Array.from({ length: 5 }, (_, i) => {
    const fecha = idDiario(new Date(ahora.getTime() + i * 24 * 3600 * 1000));
    // Los días 2 a 4 (mañana en adelante) traen el extremo; la sequía, todos.
    const extremo = cambios.acumuladoDia === 0 || (i >= 1 && i <= 3);
    return {
      fecha,
      temperaturaMinima: 18,
      temperaturaMaxima: 26,
      precipitacionHora: 0.5,
      acumuladoDia: 4,
      velocidadViento: 8,
      humedadRelativa: 70,
      ...(extremo ? cambios : {}),
    };
  });
}

async function principal() {
  const [parcelaId, escenario] = process.argv.slice(2);
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('Solo funciona con el emulador (falta FIRESTORE_EMULATOR_HOST).');
  }
  if (!parcelaId || !ESCENARIOS[escenario]) {
    throw new Error(`Uso: simular-pronostico.js <parcelaId> <${Object.keys(ESCENARIOS).join('|')}>`);
  }
  const { initializeApp } = require('firebase-admin/app');
  const { getFirestore } = require('firebase-admin/firestore');
  const db = getFirestore(initializeApp({ projectId: process.env.GCLOUD_PROJECT ?? 'agroclima-jalapa' }));

  const doc = await db.doc(`parcelas/${parcelaId}`).get();
  if (!doc.exists) throw new Error(`No existe la parcela ${parcelaId}.`);
  const ahora = new Date();
  const pronosticos = pronosticoSimulado(ahora, ESCENARIOS[escenario]);
  const lote = db.batch();
  for (const dia of pronosticos) {
    lote.set(doc.ref.collection('pronosticos').doc(dia.fecha), {
      ...dia,
      fechaConsulta: FieldValue.serverTimestamp(),
    });
  }
  await lote.commit();

  const catalogo = await leerCatalogo(db);
  const { riesgos } = await evaluarCeldas({
    db,
    celdas: [{ parcelas: [{ ...doc.data(), parcelaId }], pronosticos }],
    catalogo,
    ahora,
  });
  const alertas = await generarAlertas({ db, riesgos, ahora });
  for (const alerta of alertas) console.log(`${alerta.titulo} — ${alerta.mensaje}`);
  console.log(`${alertas.length} alertas nuevas (repetir el mismo escenario no las duplica).`);
}

principal().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
