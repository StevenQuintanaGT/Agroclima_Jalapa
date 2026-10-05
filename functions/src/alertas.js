'use strict';

/**
 * Generador de alertas (CO-13, HU-10). Por cada riesgo del motor:
 * - busca alertas de la misma parcela, tipo de riesgo y día del evento
 *   (índice 2, UMBRALES.md §5 / RO-03);
 * - si no hay, o todas son de nivel menor (el riesgo empeoró), crea la alerta;
 * - si ya hay una del mismo nivel o mayor, no hace nada.
 * Las alertas quedan en `alertas` aunque luego no se notifiquen (RT-05).
 */
const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const { inicioDelDia } = require('./fechas');
const { textosAlerta } = require('./mensajes');
const { rangoNivel } = require('./motor/comparar');

/**
 * @param {object} opciones
 * @param {import('firebase-admin/firestore').Firestore} opciones.db
 * @param {Array<object>} opciones.riesgos evaluacion.riesgos
 * @param {Date} [opciones.ahora]
 * @returns {Promise<Array<object>>} alertas creadas, con `alertaId` y `titulo`
 *   (el título solo va en la notificación, no se guarda).
 */
async function generarAlertas({ db, riesgos, ahora = new Date() }) {
  // Una consulta por parcela y tipo de riesgo, con el rango de días del evento.
  const grupos = new Map();
  for (const riesgo of riesgos) {
    const clave = `${riesgo.parcelaId}|${riesgo.tipoRiesgo}`;
    if (!grupos.has(clave)) grupos.set(clave, []);
    grupos.get(clave).push(riesgo);
  }

  const creadas = [];
  const lote = db.bulkWriter();
  for (const grupo of grupos.values()) {
    const { parcelaId, tipoRiesgo } = grupo[0];
    const fechas = grupo.map((r) => r.fechaEvento).sort();
    const existentes = await db
      .collection('alertas')
      .where('parcelaId', '==', parcelaId)
      .where('tipoRiesgo', '==', tipoRiesgo)
      .where('fechaEvento', '>=', Timestamp.fromDate(inicioDelDia(fechas[0])))
      .where('fechaEvento', '<=', Timestamp.fromDate(inicioDelDia(fechas[fechas.length - 1])))
      .get();
    const nivelPorDia = new Map();
    for (const doc of existentes.docs) {
      const dia = doc.get('fechaEvento').toMillis();
      nivelPorDia.set(dia, Math.max(nivelPorDia.get(dia) ?? -1, rangoNivel(doc.get('nivel'))));
    }

    for (const riesgo of grupo) {
      const evento = inicioDelDia(riesgo.fechaEvento);
      if ((nivelPorDia.get(evento.getTime()) ?? -1) >= rangoNivel(riesgo.nivel)) continue;
      const { titulo, mensaje, medidaSugerida } = textosAlerta(riesgo, ahora);
      const alerta = {
        usuarioId: riesgo.usuarioId,
        parcelaId,
        tipoRiesgo,
        nivel: riesgo.nivel,
        valorEsperado: riesgo.valorEsperado,
        valorUmbral: riesgo.valorUmbral,
        mensaje,
        medidaSugerida,
        fechaEvento: Timestamp.fromDate(evento),
        leida: false,
        atendida: false,
        parcelaNombre: riesgo.parcelaNombre,
        cultivo: riesgo.cultivo ?? '',
        notificada: false,
      };
      if (riesgo.diasConsecutivos !== undefined) alerta.diasConsecutivos = riesgo.diasConsecutivos;
      const ref = db.collection('alertas').doc();
      lote.create(ref, { alertaId: ref.id, ...alerta, fechaGeneracion: FieldValue.serverTimestamp() });
      creadas.push({ alertaId: ref.id, titulo, fechaEventoId: riesgo.fechaEvento, ...alerta });
    }
  }
  await lote.close();
  return creadas;
}

module.exports = { generarAlertas };
