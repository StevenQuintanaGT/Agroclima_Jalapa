'use strict';

/**
 * Evaluador de umbrales (CMP-09, HT-04; UMBRALES.md §3–§4). Recibe la
 * parcela, su pronóstico de hoy + 4 días, el historial de condiciones (para la
 * sequía) y el catálogo leído en la vuelta; devuelve los riesgos encontrados.
 * No escribe nada: crear alertas y avisar es HU-10.
 */
const { DIAS_PRONOSTICO } = require('../config');
const { aplicables } = require('../umbrales');
const reglas = require('./reglas');

// Para umbrales sin `tipoRiesgo` (campo opcional, MODELO_DATOS Tabla 70).
const TIPO_POR_VARIABLE = Object.freeze({
  precipitacionHora: 'lluviaIntensa',
  velocidadViento: 'vientoFuerte',
  diasSecos: 'sequia',
  temperaturaMinima: 'temperaturaBaja',
  temperaturaMaxima: 'temperaturaAlta',
  humedadRelativa: 'humedadAlta',
});

/**
 * @param {object} entrada
 * @param {{cultivo?: string, etapa?: string}} entrada.parcela
 * @param {Array<object>} entrada.pronosticos `pronosticos/{fecha}` de hoy en adelante
 * @param {Array<{fecha: string, precipitacion?: number}>} [entrada.historial] condiciones de días pasados
 * @param {Array<object>} entrada.catalogo resultado de leerCatalogo
 * @param {(mensaje: string) => void} [entrada.registrar]
 * @returns {Array<{tipoRiesgo: string, nivel: string, valorEsperado: number,
 *   valorUmbral: number, fechaEvento: string, umbralId: string, diasConsecutivos?: number}>}
 *   como máximo uno por tipoRiesgo y día de evento (§4.5), ordenados por fecha.
 */
function evaluarParcela({ parcela, pronosticos, historial = [], catalogo, registrar = console.log }) {
  const dias = [...pronosticos]
    .sort((a, b) => a.fecha.localeCompare(b.fecha))
    .slice(0, DIAS_PRONOSTICO);
  if (dias.length === 0) return [];

  const porTipo = new Map();
  for (const umbral of aplicables(catalogo, parcela)) {
    const tipo = umbral.tipoRiesgo ?? TIPO_POR_VARIABLE[umbral.variable];
    if (!porTipo.has(tipo)) porTipo.set(tipo, []);
    porTipo.get(tipo).push(umbral);
  }

  const resultados = [];
  for (const [tipoRiesgo, umbrales] of porTipo) {
    const regla = reglas[tipoRiesgo];
    if (!regla) {
      registrar(`Sin regla para el riesgo "${tipoRiesgo}": se omiten sus umbrales.`);
      continue;
    }
    for (const resultado of regla.evaluar({ pronosticos: dias, historial, umbrales, parcela })) {
      resultados.push({ tipoRiesgo, ...resultado });
    }
  }
  return resultados.sort(
    (a, b) => a.fechaEvento.localeCompare(b.fechaEvento) || a.tipoRiesgo.localeCompare(b.tipoRiesgo),
  );
}

module.exports = { evaluarParcela, TIPO_POR_VARIABLE };
