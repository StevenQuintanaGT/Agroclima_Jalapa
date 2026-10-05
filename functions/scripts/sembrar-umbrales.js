'use strict';

/**
 * Carga el catálogo de umbrales (functions/seed/umbrales.json) en la colección
 * `umbrales`. Es idempotente: usa `umbralId` como id del documento, así que
 * volver a ejecutarlo actualiza en lugar de duplicar (HT-03).
 *
 * Uso:
 *   Emulador:   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node functions/scripts/sembrar-umbrales.js
 *   Producción: GitHub → Actions → "Sembrar umbrales" → Run workflow (usa el
 *               secreto FIREBASE_SERVICE_ACCOUNT; D-37). En la PC, con la
 *               variable FIREBASE_SERVICE_ACCOUNT con el JSON de la cuenta.
 */
const path = require('node:path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const { validarCatalogo } = require('../src/umbrales_semilla');
const umbrales = require(path.join(__dirname, '..', 'seed', 'umbrales.json'));

const ID_PROYECTO = process.env.GCLOUD_PROJECT || 'agroclima-jalapa';

async function sembrar() {
  const problemas = validarCatalogo(umbrales);
  if (problemas.length > 0) {
    console.error('El catálogo tiene errores, no se cargó nada:');
    for (const problema of problemas) console.error(`  - ${problema}`);
    process.exitCode = 1;
    return;
  }

  const cuenta = process.env.FIREBASE_SERVICE_ACCOUNT;
  initializeApp(
    cuenta && !process.env.FIRESTORE_EMULATOR_HOST
      ? { credential: cert(JSON.parse(cuenta)) }
      : { projectId: ID_PROYECTO },
  );
  const db = getFirestore();
  const lote = db.batch();
  for (const umbral of umbrales) {
    const doc = { cultivo: '', etapa: '', duracionDias: 1, ...umbral };
    lote.set(db.collection('umbrales').doc(umbral.umbralId), doc);
  }
  await lote.commit();

  const destino = process.env.FIRESTORE_EMULATOR_HOST
    ? `emulador ${process.env.FIRESTORE_EMULATOR_HOST}`
    : `proyecto ${cuenta ? JSON.parse(cuenta).project_id : ID_PROYECTO}`;
  console.log(`${umbrales.length} umbrales cargados en ${destino}.`);
}

sembrar().catch((error) => {
  console.error('No se pudieron cargar los umbrales:', error.message);
  process.exitCode = 1;
});
