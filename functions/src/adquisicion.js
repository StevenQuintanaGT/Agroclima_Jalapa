'use strict';

/**
 * Adquisición del clima (CMP-08, plans/03 §8). En cada vuelta del ciclo:
 * 1. lee las parcelas activas y las agrupa por `celdaClima` (RN-06, D-07);
 * 2. por celda, consulta el clima actual y el pronóstico UNA vez, en el
 *    centro de la celda (2 llamadas por celda);
 * 3. si la celda falla, la registra y sigue con la siguiente;
 * 4. escribe en todas las parcelas de la celda `condiciones/{hoy}` (con la
 *    lluvia del día, D-40) y `pronosticos/{fecha}` de hoy + 4 días;
 * 5. devuelve lo escrito por celda para que el motor lo evalúe sin leerlo de
 *    nuevo (HT-04). Las celdas que fallaron no se evalúan (§4.7.2).
 */
const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const { TAMANO_CELDA_GRADOS, PAUSA_ENTRE_CELDAS_MS } = require('./config');
const { idDiario } = require('./fechas');
const { agruparPorDia } = require('./pronostico_diario');
const { esPosterior } = require('./validacion');
const { contarFranjasTerminadas, preverFranjas } = require('./lluvia_del_dia');

const UN_DIA_MS = 24 * 3600 * 1000;

/** "14.65_-90.00" → centro de la celda (el id ya es el centro redondeado). */
function centroDeCelda(celda) {
  const [lat, lon] = celda.split('_').map(Number);
  if (!Number.isFinite(lat) || !Number.isFinite(lon)) return null;
  return { lat, lon };
}

/**
 * @param {object} opciones
 * @param {import('firebase-admin/firestore').Firestore} opciones.db
 * @param {{actual: Function, pronostico: Function}} opciones.clima cliente de openweather.js
 * @param {Date} [opciones.ahora]
 * @param {(ms: number) => Promise<void>} [opciones.esperar] pausa entre celdas (cuota 60/min)
 * @param {(mensaje: string) => void} [opciones.registrar]
 * @returns {Promise<{celdas: number, llamadas: number, parcelas: number,
 *   fallidas: Array<{celda: string, motivo: string}>, actualizadas: string[],
 *   celdasActualizadas: Array<{celda: string, parcelas: Array<object>,
 *   pronosticos: Array<object>, lluviaHoy: number}>}>}
 */
async function adquirirClima({
  db,
  clima,
  ahora = new Date(),
  esperar = (ms) => new Promise((r) => setTimeout(r, ms)),
  registrar = console.log,
}) {
  const consulta = await db.collection('parcelas').where('activa', '==', true).get();
  const porCelda = new Map();
  for (const doc of consulta.docs) {
    const celda = doc.get('celdaClima');
    if (!celda) continue;
    if (!porCelda.has(celda)) porCelda.set(celda, []);
    porCelda.get(celda).push(doc);
  }

  const resumen = { celdas: porCelda.size, llamadas: 0, parcelas: 0, fallidas: [], actualizadas: [], celdasActualizadas: [] };
  let primera = true;
  for (const [celda, parcelas] of porCelda) {
    if (!primera) await esperar(PAUSA_ENTRE_CELDAS_MS);
    primera = false;
    const centro = centroDeCelda(celda);
    if (!centro) {
      resumen.fallidas.push({ celda, motivo: 'celdaInvalida' });
      continue;
    }
    let actual;
    let franjas;
    try {
      resumen.llamadas++;
      actual = await clima.actual(centro.lat, centro.lon);
      resumen.llamadas++;
      franjas = await clima.pronostico(centro.lat, centro.lon);
    } catch (error) {
      // Salida anticipada de la celda: queda el dato previo y no hay alertas.
      resumen.fallidas.push({ celda, motivo: error.motivo ?? error.message });
      registrar(`Celda ${celda}: sin datos (${error.motivo ?? error.message})`);
      continue;
    }
    const refs = parcelas.map((doc) => doc.ref);
    const { dias, lluviaHoy } = await guardarCelda({ db, parcelas: refs, actual, franjas, ahora });
    resumen.parcelas += parcelas.length;
    resumen.actualizadas.push(...refs.map((ref) => ref.id));
    resumen.celdasActualizadas.push({
      celda,
      parcelas: parcelas.map((doc) => ({ ...doc.data(), parcelaId: doc.id })),
      pronosticos: dias,
      lluviaHoy,
    });
  }
  registrar(
    `Clima: ${resumen.celdas} celdas, ${resumen.llamadas} llamadas, ` +
      `${resumen.parcelas} parcelas actualizadas, ${resumen.fallidas.length} celdas con error.`,
  );
  return resumen;
}

async function guardarCelda({ db, parcelas, actual, franjas, ahora }) {
  const hoy = idDiario(ahora);
  const ayer = idDiario(new Date(ahora.getTime() - UN_DIA_MS));
  const dias = agruparPorDia(franjas).filter((dia) => dia.fecha >= hoy);

  // Todas las parcelas de la celda comparten el clima: la cuenta de la lluvia
  // se hace con la primera y se copia a las demás.
  const muestra = parcelas[0];
  const [docAyer, docHoy] = await db.getAll(
    muestra.collection('condiciones').doc(ayer),
    muestra.collection('condiciones').doc(hoy),
  );

  // Ayer: solo se cierran las franjas que terminaron después de medianoche.
  const cierreAyer = docAyer.exists ? contarFranjasTerminadas(docAyer.data(), ahora) : null;

  // Hoy: se suma lo que ya pasó y se prevé el resto con el pronóstico nuevo.
  const guardadoHoy = docHoy.exists ? docHoy.data() : {};
  const cuentaHoy = contarFranjasTerminadas(guardadoHoy, ahora);
  const lluviaPrevista = preverFranjas(
    cuentaHoy.lluviaPrevista,
    franjas,
    hoy,
    idDiario,
    cuentaHoy.franjasContadas,
  );

  // VA-08: la observación debe ser más nueva que la guardada.
  const fechaGuardada = guardadoHoy.fechaHora?.toDate?.() ?? null;
  const observacion = esPosterior(actual.fechaHora, fechaGuardada)
    ? {
        fechaHora: Timestamp.fromDate(actual.fechaHora),
        temperatura: actual.temperatura,
        humedadRelativa: actual.humedadRelativa,
        velocidadViento: actual.velocidadViento,
        origen: 'ciclo',
        vigente: true,
      }
    : {};

  const lote = db.bulkWriter();
  for (const parcela of parcelas) {
    const condiciones = parcela.collection('condiciones');
    lote.set(
      condiciones.doc(hoy),
      {
        fecha: hoy,
        ...observacion,
        precipitacion: cuentaHoy.precipitacion,
        lluviaPrevista,
        franjasContadas: cuentaHoy.franjasContadas,
      },
      { merge: true },
    );
    if (cierreAyer) {
      lote.set(
        condiciones.doc(ayer),
        {
          precipitacion: cierreAyer.precipitacion,
          lluviaPrevista: cierreAyer.lluviaPrevista,
          franjasContadas: cierreAyer.franjasContadas,
        },
        { merge: true },
      );
    }
    for (const dia of dias) {
      lote.set(parcela.collection('pronosticos').doc(dia.fecha), {
        ...dia,
        fechaConsulta: FieldValue.serverTimestamp(),
      });
    }
  }
  await lote.close();

  // Lluvia de hoy completa: lo que ya cayó más lo que falta según el pronóstico.
  const pendiente = Object.values(lluviaPrevista ?? {}).reduce((a, b) => a + b, 0);
  return { dias, lluviaHoy: Math.round((cuentaHoy.precipitacion + pendiente) * 100) / 100 };
}

module.exports = { adquirirClima, centroDeCelda };
