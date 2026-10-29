'use strict';

/**
 * Exporta las encuestas de satisfacción (D-58) a `encuestas.csv`: una fila
 * por respuesta, sin correo ni uid (ver src/encuestas_csv.js). El archivo
 * tiene datos personales: no se sube a git (.gitignore) y se guarda fuera
 * del repositorio.
 *
 * Uso:
 *   Producción: FIREBASE_SERVICE_ACCOUNT='<JSON de la cuenta>' node functions/scripts/exportar-encuestas.js [archivo.csv]
 *   Emulador:   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node functions/scripts/exportar-encuestas.js [archivo.csv]
 */
const fs = require('node:fs');
const path = require('node:path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const { encuestasACsv } = require('../src/encuestas_csv');

const ID_PROYECTO = process.env.GCLOUD_PROJECT || 'agroclima-jalapa';

async function exportar() {
  const destino = path.resolve(process.argv[2] || 'encuestas.csv');
  const cuenta = process.env.FIREBASE_SERVICE_ACCOUNT;
  initializeApp(
    cuenta && !process.env.FIRESTORE_EMULATOR_HOST
      ? { credential: cert(JSON.parse(cuenta)) }
      : { projectId: ID_PROYECTO },
  );
  const db = getFirestore();
  const consulta = await db.collection('encuestas').orderBy('fechaRespuesta').get();
  const encuestas = [];
  for (const doc of consulta.docs) {
    const perfil = await db.doc(`usuarios/${doc.id}`).get();
    const datos = doc.data();
    encuestas.push({
      datos: { ...datos, fechaRespuesta: datos.fechaRespuesta?.toDate?.() },
      nombre: perfil.get('nombre'),
    });
  }
  fs.writeFileSync(destino, encuestasACsv(encuestas), 'utf8');
  console.log(`${encuestas.length} encuestas en ${destino}`);
}

exportar().catch((error) => {
  console.error('No se pudieron exportar las encuestas:', error.message);
  process.exitCode = 1;
});
