'use strict';

/**
 * Piezas comunes de las reglas del motor (UMBRALES.md §4): operadores,
 * orden de niveles y elección del umbral que define el nivel.
 */
const { NIVELES } = require('../config');

const OPERADORES = Object.freeze({
  mayor: (valor, umbral) => valor > umbral,
  mayorIgual: (valor, umbral) => valor >= umbral,
  menor: (valor, umbral) => valor < umbral,
  menorIgual: (valor, umbral) => valor <= umbral,
});

/** ¿El valor cumple el umbral según su operador? */
function cumple(valor, umbral) {
  const operar = OPERADORES[umbral.operador];
  return typeof valor === 'number' && Number.isFinite(valor) && operar !== undefined
    ? operar(valor, umbral.valor)
    : false;
}

/** informativa = 0, preventiva = 1, critica = 2. */
const rangoNivel = (nivel) => NIVELES.indexOf(nivel);

/**
 * Umbral que define el nivel entre los cumplidos (§4.4): el de nivel más alto;
 * a igual nivel, el específico del cultivo antes que el general (su valor es
 * "lo que aguanta el cultivo", D-14); después, el orden del catálogo.
 * @param {Array<object>} cumplidos
 */
function definitorio(cumplidos) {
  let mejor = null;
  for (const umbral of cumplidos) {
    if (
      mejor === null ||
      rangoNivel(umbral.nivel) > rangoNivel(mejor.nivel) ||
      (rangoNivel(umbral.nivel) === rangoNivel(mejor.nivel) &&
        mejor.cultivo === '' &&
        umbral.cultivo !== '')
    ) {
      mejor = umbral;
    }
  }
  return mejor;
}

module.exports = { cumple, rangoNivel, definitorio, OPERADORES };
