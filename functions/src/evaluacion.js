'use strict';

/**
 * Paso de evaluación del ciclo (HT-04). Corre al final de la adquisición y
 * solo con las celdas que obtuvieron clima en esta vuelta: si OpenWeather no
 * respondió o la respuesta no pasó VA-06..VA-08, esa celda no se evalúa.
 *
 * El catálogo se lee una vez por vuelta. El historial de lluvia (para la
 * sequía) es el mismo para todas las parcelas de una celda, así que se lee una
 * vez por celda, de la parcela con más días registrados.
 */
const { DIAS_HISTORIAL_SEQUIA } = require('./config');
const { idDiario } = require('./fechas');
const { evaluarParcela } = require('./motor/evaluador');

/**
 * @param {object} opciones
 * @param {import('firebase-admin/firestore').Firestore} opciones.db
 * @param {Array<object>} opciones.celdas adquisicion.celdasActualizadas
 * @param {Array<object>} opciones.catalogo resultado de leerCatalogo
 * @param {Date} [opciones.ahora]
 * @param {(mensaje: string) => void} [opciones.registrar]
 * @returns {Promise<{parcelas: number, riesgos: Array<object>}>} cada riesgo
 *   lleva los datos de la parcela que HU-10 necesita para la alerta.
 */
async function evaluarCeldas({ db, celdas, catalogo, ahora = new Date(), registrar = console.log }) {
  const hoy = idDiario(ahora);
  const resumen = { parcelas: 0, riesgos: [] };
  if (catalogo.length === 0) {
    registrar('Motor: el catálogo de umbrales está vacío; no se evalúa nada.');
    return resumen;
  }

  for (const { parcelas, pronosticos, lluviaHoy } of celdas) {
    const historial = await leerHistorial(db, parcelas, hoy);
    // Para la sequía, hoy cuenta con la lluvia que ya cayó más la que falta.
    const dias = pronosticos.map((dia) =>
      dia.fecha === hoy && typeof lluviaHoy === 'number' ? { ...dia, acumuladoDia: lluviaHoy } : dia,
    );
    for (const parcela of parcelas) {
      resumen.parcelas++;
      const riesgos = evaluarParcela({ parcela, pronosticos: dias, historial, catalogo, registrar });
      for (const riesgo of riesgos) {
        resumen.riesgos.push({
          parcelaId: parcela.parcelaId,
          usuarioId: parcela.usuarioId,
          parcelaNombre: parcela.nombre ?? '',
          cultivo: parcela.cultivo ?? '',
          ...riesgo,
        });
      }
    }
  }
  registrar(`Motor: ${resumen.parcelas} parcelas evaluadas, ${resumen.riesgos.length} riesgos.`);
  return resumen;
}

/** Últimos días de `condiciones` antes de hoy (más nuevo primero en la consulta). */
async function leerHistorial(db, parcelas, hoy) {
  // La parcela registrada primero es la que tiene más historial de la celda.
  const muestra = [...parcelas].sort(
    (a, b) => (a.fechaRegistro?.toMillis?.() ?? 0) - (b.fechaRegistro?.toMillis?.() ?? 0),
  )[0];
  const consulta = await db
    .collection('parcelas')
    .doc(muestra.parcelaId)
    .collection('condiciones')
    .where('fecha', '<', hoy)
    .orderBy('fecha', 'desc')
    .limit(DIAS_HISTORIAL_SEQUIA)
    .get();
  return consulta.docs.map((doc) => ({ fecha: doc.id, precipitacion: doc.get('precipitacion') }));
}

module.exports = { evaluarCeldas };
