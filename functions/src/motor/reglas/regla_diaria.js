'use strict';

/**
 * Regla para variables diarias del pronóstico (UMBRALES.md §4.2): cada día se
 * compara su valor con cada umbral. Si el umbral pide `duracionDias > 1`, el
 * día cuenta solo si forma parte de una racha de días seguidos del pronóstico
 * que lo cumplen, de al menos esa longitud.
 */
const { cumple, definitorio } = require('../comparar');

/**
 * Racha (días seguidos que cumplen) a la que pertenece cada día:
 * su longitud y el índice del día en que empieza.
 */
function rachas(pronosticos, variable, umbral) {
  const lista = pronosticos.map(() => ({ longitud: 0, inicio: -1 }));
  let inicio = 0;
  for (let i = 0; i <= pronosticos.length; i++) {
    const sigue = i < pronosticos.length && cumple(pronosticos[i][variable], umbral);
    if (sigue) continue;
    for (let j = inicio; j < i; j++) lista[j] = { longitud: i - inicio, inicio };
    inicio = i + 1;
  }
  return lista;
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
          (u) => rachasPorUmbral.get(u)[i].longitud >= Math.max(1, u.duracionDias ?? 1),
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
          // Para el mensaje: "Desde mañana, 3 días seguidos…" en cada día de la racha.
          const racha = rachasPorUmbral.get(umbral)[i];
          resultado.diasConsecutivos = racha.longitud;
          resultado.inicioRacha = pronosticos[racha.inicio].fecha;
        }
        resultados.push(resultado);
      });
      return resultados;
    },
  };
}

module.exports = { crearReglaDiaria };
