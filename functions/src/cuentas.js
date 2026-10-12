'use strict';

/**
 * Eliminación de cuentas (Ajustes → "Eliminar mi cuenta", MODELO_DATOS §6).
 * Reemplaza a la función invocable `eliminarCuenta`, que exige el plan Blaze
 * (DECISIONES D-37): la app marca `usuarios/{uid}.eliminacionSolicitada`,
 * vacía sus tokens de avisos y cierra la sesión; en la siguiente vuelta del
 * ciclo (≤ 3 h) esto borra todo.
 *
 * Orden: primero el usuario de Auth (ya no puede entrar ni recrear su perfil),
 * después parcelas con su historial, alertas, preferencias y el perfil. Si
 * algo falla a medias, el perfil con la marca sigue ahí y la próxima vuelta
 * lo vuelve a intentar.
 */
const { borrarAlertasDonde } = require('./limpieza');

/**
 * @param {import('firebase-admin/firestore').Firestore} db
 * @param {{deleteUser: (uid: string) => Promise<void>}} auth Auth de firebase-admin
 * @param {(texto: string) => void} [registrar]
 * @returns {Promise<string[]>} uids eliminados
 */
async function eliminarCuentasSolicitadas(db, auth, registrar = console.log) {
  const solicitudes = await db
    .collection('usuarios')
    .where('eliminacionSolicitada', '!=', null)
    .select()
    .get();
  const eliminadas = [];
  for (const doc of solicitudes.docs) {
    try {
      await eliminarCuenta(db, auth, doc);
      eliminadas.push(doc.id);
    } catch (error) {
      // Una cuenta que falla no detiene el ciclo del clima.
      registrar(`No se pudo eliminar una cuenta: ${error.message}`);
    }
  }
  return eliminadas;
}

async function eliminarCuenta(db, auth, doc) {
  const uid = doc.id;
  await borrarAcceso(auth, uid);
  const parcelas = await db.collection('parcelas').where('usuarioId', '==', uid).select().get();
  for (const parcela of parcelas.docs) {
    await db.recursiveDelete(parcela.ref);
  }
  // Las alertas llevan `usuarioId`: así caen también las de parcelas ya borradas.
  await borrarAlertasDonde(db, 'usuarioId', uid);
  await db.recursiveDelete(doc.ref);
}

async function borrarAcceso(auth, uid) {
  try {
    await auth.deleteUser(uid);
  } catch (error) {
    // Ya no existe (lo borró una vuelta anterior que falló después).
    if (error?.code !== 'auth/user-not-found') throw error;
  }
}

module.exports = { eliminarCuentasSolicitadas };
