'use strict';

/**
 * Catálogo de umbrales (CO-11, HT-03). Los umbrales NO están en el código:
 * se leen de la colección `umbrales` en cada vuelta del ciclo, así que un
 * umbral nuevo o corregido en Firestore se usa en la siguiente vuelta sin
 * tocar nada más (RNF-19).
 */
const { validarUmbral } = require('./umbrales_semilla');

/**
 * Lee los umbrales vigentes (una vez por vuelta del ciclo). Los que tienen
 * errores se ignoran y se reportan, para que un dato mal escrito en la
 * consola de Firebase no detenga el ciclo.
 * @param {import('firebase-admin/firestore').Firestore} db
 * @param {(mensaje: string) => void} [registrar]
 */
async function leerCatalogo(db, registrar = console.log) {
  const consulta = await db.collection('umbrales').where('vigente', '==', true).get();
  const catalogo = [];
  for (const doc of consulta.docs) {
    const umbral = { cultivo: '', etapa: '', duracionDias: 1, umbralId: doc.id, ...doc.data() };
    const problemas = validarUmbral(umbral);
    if (problemas.length > 0) {
      registrar(`Umbral ${doc.id} ignorado: ${problemas.join('; ')}`);
      continue;
    }
    catalogo.push(umbral);
  }
  return catalogo;
}

/**
 * Umbrales que aplican a una parcela (UMBRALES.md §3): los generales y los
 * de su cultivo (en cualquier etapa o en su etapa). Sin cultivo, solo los
 * generales (RN-05).
 * @param {Array<object>} catalogo resultado de leerCatalogo
 * @param {{cultivo?: string, etapa?: string}} parcela
 */
function aplicables(catalogo, parcela) {
  const cultivo = parcela.cultivo ?? '';
  const etapa = parcela.etapa ?? '';
  return catalogo.filter(
    (u) =>
      u.vigente !== false &&
      (u.cultivo === '' ||
        (cultivo !== '' && u.cultivo === cultivo && (u.etapa === '' || u.etapa === etapa))),
  );
}

module.exports = { leerCatalogo, aplicables };
