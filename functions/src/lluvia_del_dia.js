'use strict';

/**
 * Lluvia acumulada del día para `condiciones.precipitacion` (DECISIONES D-40,
 * opción A). Current Weather solo da la lluvia de la última hora, así que el
 * ciclo suma la lluvia de las franjas de 3 h del pronóstico que ya pasaron.
 *
 * Cada documento `condiciones/{yyyyMMdd}` lleva dos campos de apoyo:
 * - `lluviaPrevista`: { "<inicio en segundos UTC>": mm } de las franjas de
 *   ese día que aún no se cuentan (del pronóstico más reciente);
 * - `franjasContadas`: inicios ya sumados, para no contar dos veces.
 */
const DURACION_FRANJA_S = 3 * 3600;

/**
 * Suma a la lluvia del día las franjas previstas que ya terminaron.
 * @param {{precipitacion?: number, lluviaPrevista?: object, franjasContadas?: string[]}} guardado
 * @param {Date} ahora
 * @returns {{precipitacion: number, lluviaPrevista: object, franjasContadas: string[]}}
 */
function contarFranjasTerminadas(guardado, ahora) {
  const contadas = new Set(guardado?.franjasContadas ?? []);
  const pendientes = {};
  let precipitacion = guardado?.precipitacion ?? 0;
  const segundosAhora = ahora.getTime() / 1000;
  for (const [inicio, mm] of Object.entries(guardado?.lluviaPrevista ?? {})) {
    if (contadas.has(inicio)) continue;
    if (Number(inicio) + DURACION_FRANJA_S <= segundosAhora) {
      precipitacion += mm;
      contadas.add(inicio);
    } else {
      pendientes[inicio] = mm;
    }
  }
  return {
    precipitacion: Math.round(precipitacion * 100) / 100,
    lluviaPrevista: pendientes,
    franjasContadas: [...contadas].sort(),
  };
}

/**
 * Agrega a las pendientes las franjas del pronóstico nuevo que caen en [dia]
 * (el pronóstico nuevo manda sobre el viejo en las franjas repetidas).
 * @param {object} pendientes resultado.lluviaPrevista de contarFranjasTerminadas
 * @param {Array<{fechaHora: Date, lluvia3h: number}>} franjas
 * @param {string} dia yyyyMMdd
 * @param {(instante: Date) => string} idDiario
 * @param {string[]} contadas para no volver a prever lo ya sumado
 */
function preverFranjas(pendientes, franjas, dia, idDiario, contadas) {
  const yaSumadas = new Set(contadas);
  const prevista = { ...pendientes };
  for (const franja of franjas) {
    const inicio = String(franja.fechaHora.getTime() / 1000);
    if (idDiario(franja.fechaHora) === dia && !yaSumadas.has(inicio)) {
      prevista[inicio] = franja.lluvia3h;
    }
  }
  return prevista;
}

module.exports = { contarFranjasTerminadas, preverFranjas, DURACION_FRANJA_S };
