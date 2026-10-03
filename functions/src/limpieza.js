'use strict';

/**
 * Limpieza de parcelas borradas (HU-06, MODELO_DATOS §6). Reemplaza al
 * disparador `onDocumentDeleted` de Cloud Functions, que exige el plan Blaze
 * (DECISIONES D-37): la app borra solo el documento de la parcela y, en la
 * siguiente vuelta del ciclo (≤ 3 h), esto borra su historial y sus alertas.
 *
 * Cómo encuentra las borradas: `listDocuments()` también devuelve los
 * documentos que ya no existen pero conservan subcolecciones (`condiciones`,
 * `pronosticos`). Las alertas de una parcela solo nacen después de guardar su
 * pronóstico, así que toda parcela borrada con alertas aparece en esa lista.
 */

/** Cuántas lecturas o escrituras se agrupan por llamada. */
const LOTE = 300;

/**
 * Borra historial y alertas de las parcelas que ya no existen.
 * @param {import('firebase-admin/firestore').Firestore} db
 * @returns {Promise<{existentes: string[], limpiadas: string[]}>}
 *   ids de las parcelas que siguen (el ciclo de clima los reutiliza) y de las
 *   que se limpiaron.
 */
async function limpiarParcelasBorradas(db) {
  const referencias = await db.collection('parcelas').listDocuments();
  const existentes = [];
  const borradas = [];
  for (let i = 0; i < referencias.length; i += LOTE) {
    const lote = referencias.slice(i, i + LOTE);
    const documentos = await db.getAll(...lote);
    documentos.forEach((doc, j) => {
      (doc.exists ? existentes : borradas).push(lote[j]);
    });
  }

  const limpiadas = [];
  for (const referencia of borradas) {
    // Primero las alertas: si algo falla, el documento fantasma sigue ahí y
    // la próxima vuelta lo vuelve a intentar.
    await borrarAlertasDe(db, referencia.id);
    await db.recursiveDelete(referencia);
    limpiadas.push(referencia.id);
  }
  return { existentes: existentes.map((ref) => ref.id), limpiadas };
}

async function borrarAlertasDe(db, parcelaId) {
  const alertas = await db
    .collection('alertas')
    .where('parcelaId', '==', parcelaId)
    .select()
    .get();
  for (let i = 0; i < alertas.docs.length; i += LOTE) {
    const lote = db.batch();
    alertas.docs.slice(i, i + LOTE).forEach((doc) => lote.delete(doc.ref));
    await lote.commit();
  }
}

module.exports = { limpiarParcelasBorradas };
