'use strict';

/**
 * Validaciones de los datos del clima antes de guardarlos (REQUISITOS §7).
 * Lo que no pasa se descarta: queda el dato previo y no se generan alertas.
 */
const { RANGOS_VALIDOS } = require('./config');

const dentro = (valor, { min, max }) =>
  typeof valor === 'number' && Number.isFinite(valor) && valor >= min && valor <= max;

/** VA-07: valores posibles para la región. */
function enRango({ temperatura, humedadRelativa, velocidadViento, lluviaPorHora = 0 }) {
  return (
    dentro(temperatura, RANGOS_VALIDOS.temperatura) &&
    dentro(humedadRelativa, RANGOS_VALIDOS.humedad) &&
    dentro(velocidadViento, RANGOS_VALIDOS.vientoKmHora) &&
    dentro(lluviaPorHora, RANGOS_VALIDOS.lluviaMmHora)
  );
}

/** VA-08: el dato nuevo debe ser posterior al último guardado. */
function esPosterior(nuevo, ultimoGuardado) {
  return ultimoGuardado == null || nuevo.getTime() > ultimoGuardado.getTime();
}

module.exports = { enRango, esPosterior };
