'use strict';

/**
 * Alertas de prueba para revisar los avisos en un teléfono real, sin esperar
 * a que el clima pase un umbral. Crea 2 alertas en la primera parcela de la
 * cuenta (helada = PELIGRO mañana; lluvia fuerte = PRECAUCIÓN pasado mañana),
 * con los textos reales del ciclo, y las manda por FCM sin filtros de
 * preferencias ni de horario (es una prueba pedida a mano).
 *
 * Quedan marcadas `prueba: true` y el título de la notificación empieza con
 * "Prueba ·". Con `borrar` se quitan todas las alertas de prueba de la cuenta.
 *
 *   node scripts/alertas-de-prueba.js <correo> enviar|borrar
 *
 * En producción: Actions → "Alertas de prueba" (secreto FIREBASE_SERVICE_ACCOUNT).
 */
const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const { idDiario, inicioDelDia } = require('../src/fechas');
const { textosAlerta } = require('../src/mensajes');
const { mensajeFcm } = require('../src/notificaciones');

const DIA_MS = 24 * 3600 * 1000;

/** Los 2 riesgos simulados de una parcela. */
function riesgosDePrueba(parcela, uid, ahora) {
  const base = {
    usuarioId: uid,
    parcelaId: parcela.id,
    parcelaNombre: parcela.get('nombre'),
    cultivo: parcela.get('cultivo') ?? '',
  };
  return [
    {
      ...base,
      tipoRiesgo: 'temperaturaBaja',
      nivel: 'critica',
      valorEsperado: -1,
      valorUmbral: 0,
      fechaEvento: idDiario(new Date(ahora.getTime() + DIA_MS)),
    },
    {
      ...base,
      tipoRiesgo: 'lluviaIntensa',
      nivel: 'preventiva',
      valorEsperado: 22,
      valorUmbral: 15,
      fechaEvento: idDiario(new Date(ahora.getTime() + 2 * DIA_MS)),
    },
  ];
}

async function enviar({ db, mensajeria, uid, ahora, registrar }) {
  const parcelas = await db.collection('parcelas').where('usuarioId', '==', uid).get();
  if (parcelas.empty) throw new Error('La cuenta no tiene parcelas: registre una en la app primero.');
  const parcela = parcelas.docs.sort((a, b) => a.get('nombre').localeCompare(b.get('nombre')))[0];
  const perfil = await db.doc(`usuarios/${uid}`).get();
  const tokens = [...new Set(perfil.get('tokensFcm') ?? [])];

  for (const riesgo of riesgosDePrueba(parcela, uid, ahora)) {
    const { titulo, mensaje, medidaSugerida } = textosAlerta(riesgo, ahora);
    const ref = db.collection('alertas').doc();
    const alerta = {
      alertaId: ref.id,
      usuarioId: uid,
      parcelaId: riesgo.parcelaId,
      tipoRiesgo: riesgo.tipoRiesgo,
      nivel: riesgo.nivel,
      valorEsperado: riesgo.valorEsperado,
      valorUmbral: riesgo.valorUmbral,
      mensaje,
      medidaSugerida,
      fechaEvento: Timestamp.fromDate(inicioDelDia(riesgo.fechaEvento)),
      fechaGeneracion: FieldValue.serverTimestamp(),
      leida: false,
      atendida: false,
      parcelaNombre: riesgo.parcelaNombre,
      cultivo: riesgo.cultivo,
      notificada: tokens.length > 0,
      prueba: true,
    };
    await ref.create(alerta);
    if (tokens.length === 0) {
      registrar('Alerta creada, pero la cuenta no tiene teléfonos con sesión: no se avisa.');
      continue;
    }
    const respuesta = await mensajeria.sendEachForMulticast(
      mensajeFcm({ ...alerta, titulo: `Prueba · ${titulo}` }, tokens),
    );
    registrar(
      `${titulo}: ${respuesta.successCount} de ${tokens.length} teléfonos` +
        (respuesta.failureCount ? ` (${respuesta.responses.find((r) => !r.success)?.error?.code})` : ''),
    );
  }
}

async function borrar({ db, uid, registrar }) {
  const pruebas = await db
    .collection('alertas')
    .where('usuarioId', '==', uid)
    .where('prueba', '==', true)
    .get();
  const lote = db.batch();
  pruebas.docs.forEach((doc) => lote.delete(doc.ref));
  await lote.commit();
  registrar(`Alertas de prueba borradas: ${pruebas.size}.`);
}

async function principal() {
  const [correo, accion = 'enviar'] = process.argv.slice(2);
  if (!correo || !['enviar', 'borrar'].includes(accion)) {
    throw new Error('Uso: alertas-de-prueba.js <correo> enviar|borrar');
  }
  // Aquí y no arriba: así las pruebas cargan el archivo sin Auth ni FCM.
  const { initializeApp, cert } = require('firebase-admin/app');
  const { getFirestore } = require('firebase-admin/firestore');
  const { getAuth } = require('firebase-admin/auth');
  const { getMessaging } = require('firebase-admin/messaging');
  const cuenta = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!cuenta) throw new Error('Falta el secreto FIREBASE_SERVICE_ACCOUNT.');
  const app = initializeApp({ credential: cert(JSON.parse(cuenta)) });
  const db = getFirestore(app);
  let uid;
  try {
    uid = (await getAuth(app).getUserByEmail(correo.trim())).uid;
  } catch {
    throw new Error('No hay una cuenta con ese correo.');
  }
  const opciones = { db, uid, ahora: new Date(), registrar: console.log };
  if (accion === 'borrar') await borrar(opciones);
  else await enviar({ ...opciones, mensajeria: getMessaging(app) });
}

if (require.main === module) {
  principal().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}

module.exports = { riesgosDePrueba };
