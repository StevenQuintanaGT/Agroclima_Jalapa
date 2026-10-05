'use strict';

/**
 * Ciclo automático. No es una Cloud Function: lo ejecuta GitHub Actions cada
 * 3 horas (.github/workflows/ciclo-clima.yml, DECISIONES D-37) con el SDK de
 * administración de Firebase, que funciona en el plan gratuito Spark.
 *
 *   node index.js        (necesita OPENWEATHER_KEY y FIREBASE_SERVICE_ACCOUNT)
 *
 * Pasos de cada vuelta:
 * 1. limpieza de parcelas borradas (HU-06)
 * 2. adquisición del clima por celda (Etapa 3)
 * 3. evaluación de umbrales de las celdas actualizadas (HT-04)
 * 4. alertas y envío FCM (HU-10, pendiente)
 */
const { limpiarParcelasBorradas } = require('./src/limpieza');
const { adquirirClima } = require('./src/adquisicion');
const { crearCliente } = require('./src/openweather');
const { leerCatalogo } = require('./src/umbrales');
const { evaluarCeldas } = require('./src/evaluacion');

async function ejecutarCiclo({ db, clima, ahora = new Date(), registrar = console.log }) {
  const limpieza = await limpiarParcelasBorradas(db);
  if (limpieza.limpiadas.length > 0) {
    registrar(`Limpieza: ${limpieza.limpiadas.length} parcelas borradas.`);
  }
  const adquisicion = await adquirirClima({ db, clima, ahora, registrar });
  let evaluacion = { parcelas: 0, riesgos: [] };
  if (adquisicion.celdasActualizadas.length > 0) {
    const catalogo = await leerCatalogo(db, registrar);
    evaluacion = await evaluarCeldas({
      db,
      celdas: adquisicion.celdasActualizadas,
      catalogo,
      ahora,
      registrar,
    });
  }
  // TODO(HU-10): crear alertas sin duplicar y avisar por FCM con evaluacion.riesgos.
  return { limpieza, adquisicion, evaluacion };
}

/** Arranque desde GitHub Actions o la terminal. */
async function principal() {
  const { initializeApp, cert } = require('firebase-admin/app');
  const { getFirestore } = require('firebase-admin/firestore');

  const clave = process.env.OPENWEATHER_KEY;
  const cuenta = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!clave || (!cuenta && !process.env.FIRESTORE_EMULATOR_HOST)) {
    throw new Error('Faltan los secretos OPENWEATHER_KEY o FIREBASE_SERVICE_ACCOUNT.');
  }
  const app = cuenta
    ? initializeApp({ credential: cert(JSON.parse(cuenta)) })
    : initializeApp({ projectId: process.env.GCLOUD_PROJECT ?? 'agroclima-jalapa' });
  const db = getFirestore(app);

  const { adquisicion } = await ejecutarCiclo({ db, clima: crearCliente({ clave }) });
  // Si ninguna celda se pudo consultar (clave mala, servicio caído), la tarea
  // falla para que GitHub lo avise por correo.
  if (adquisicion.celdas > 0 && adquisicion.fallidas.length === adquisicion.celdas) {
    throw new Error(`Ninguna celda obtuvo clima (${adquisicion.fallidas[0].motivo}).`);
  }
}

if (require.main === module) {
  principal().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}

module.exports = { ejecutarCiclo, limpiarParcelasBorradas, adquirirClima };
