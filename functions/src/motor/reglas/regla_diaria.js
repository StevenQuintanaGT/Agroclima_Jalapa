'use strict';

/**
 * Regla para variables diarias del pronóstico (UMBRALES.md §4.2): cada día se
 * compara su valor con cada umbral. Si el umbral pide `duracionDias > 1`, el
 * día cuenta solo si forma parte de una racha de días seguidos del pronóstico
 * que lo cumplen, de al menos esa longitud.
 */
const { cumple, definitorio } = require('../comparar');

/** Longitud de la racha (días seguidos que cumplen) a la que pertenece cada día. */
function rachas(pronosticos, variable, umbral) {
  const longitudes = new Array(pronosticos.length).fill(0);
  let inicio = 0;
  for (let i = 0; i <= pronosticos.length; i++) {
    const sigue = i < pronosticos.length && cumple(pronosticos[i][variable], umbral);
    if (sigue) continue;
    for (let j = inicio; j < i; j++) longitudes[j] = i - inicio;
    inicio = i + 1;
  }
  return longitudes;
}

/**
 * @param {string} variable campo de `pronosticos/{fecha}` que se evalúa
 * @returns {{evaluar: Function}} regla con la interfaz de §4.1
 */
function crearReglaDiaria(variable) {
  return {
    variable,
    evaluar({ pronosticos, umbrales }) {
      const propios = umbrales.filter((u) => u.variable === variable);
      const rachasPorUmbral = new Map(
        propios.map((u) => [u, rachas(pronosticos, variable, u)]),
      );
      const resultados = [];
      pronosticos.forEach((dia, i) => {
        const cumplidos = propios.filter(
          (u) => rachasPorUmbral.get(u)[i] >= Math.max(1, u.duracionDias ?? 1),
        );
        const umbral = definitorio(cumplidos);
        if (!umbral) return;
        const resultado = {
          nivel: umbral.nivel,
          valorEsperado: dia[variable],
          valorUmbral: umbral.valor,
          fechaEvento: dia.fecha,
          umbralId: umbral.umbralId,
        };
        if ((umbral.duracionDias ?? 1) > 1) {
          resultado.diasConsecutivos = rachasPorUmbral.get(umbral)[i];
        }
        resultados.push(resultado);
      });
      return resultados;
    },
  };
}

module.exports = { crearReglaDiaria };
