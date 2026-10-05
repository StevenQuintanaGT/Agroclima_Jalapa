'use strict';

/**
 * Regla de sequía (UMBRALES.md §4.3). Día seco = lluvia del día < 1 mm
 * (Zhang et al., 2011). La racha une los últimos días secos del historial
 * (`condiciones`) con los días secos del pronóstico.
 *
 * Por cada racha que llega al pronóstico se da como máximo un resultado:
 * - valorEsperado = días secos seguidos al final de la racha dentro del pronóstico;
 * - nivel = el más alto que alcanza esa cuenta;
 * - fechaEvento = el día en que la racha llega al umbral de ese nivel. Así la
 *   misma sequía conserva su fecha de una vuelta a otra y el control de
 *   duplicados no la repite cada día (DECISIONES D-46).
 */
const { UMBRAL_DIA_SECO_MM } = require('../../config');
const { diaAnterior } = require('../../fechas');
const { cumple, definitorio } = require('../comparar');

const VARIABLE = 'diasSecos';

const esSeco = (mm) => typeof mm === 'number' && mm < UMBRAL_DIA_SECO_MM;

/**
 * Días secos seguidos del historial que terminan justo antes de `primerDia`.
 * Se corta en el primer día con lluvia, sin dato o que falta (si no hay
 * historial suficiente, se cuenta solo con lo disponible).
 * @returns {Array<string>} fechas de la racha, de la más vieja a la más nueva
 */
function rachaDelHistorial(historial, primerDia) {
  const porFecha = new Map(historial.map((c) => [c.fecha, c]));
  const fechas = [];
  let fecha = diaAnterior(primerDia);
  while (porFecha.has(fecha) && esSeco(porFecha.get(fecha).precipitacion)) {
    fechas.unshift(fecha);
    fecha = diaAnterior(fecha);
  }
  return fechas;
}

function evaluar({ pronosticos, historial = [], umbrales }) {
  const propios = umbrales.filter((u) => u.variable === VARIABLE);
  if (propios.length === 0 || pronosticos.length === 0) return [];

  const resultados = [];
  let racha = rachaDelHistorial(historial, pronosticos[0].fecha);
  let enPronostico = 0;

  const cerrar = () => {
    if (enPronostico > 0) {
      const resultado = resultadoDeRacha(racha, propios);
      if (resultado) resultados.push(resultado);
    }
    racha = [];
    enPronostico = 0;
  };

  for (const dia of pronosticos) {
    if (esSeco(dia.acumuladoDia)) {
      racha.push(dia.fecha);
      enPronostico++;
    } else {
      cerrar();
    }
  }
  cerrar();
  return resultados;
}

function resultadoDeRacha(racha, umbrales) {
  const dias = racha.length;
  const umbral = definitorio(umbrales.filter((u) => cumple(dias, u)));
  if (!umbral) return null;
  // Primer día de la racha en que la cuenta ya cumple el umbral del nivel.
  const indice = racha.findIndex((_, i) => cumple(i + 1, umbral));
  return {
    nivel: umbral.nivel,
    valorEsperado: dias,
    valorUmbral: umbral.valor,
    fechaEvento: racha[indice],
    umbralId: umbral.umbralId,
    diasConsecutivos: dias,
  };
}

module.exports = { variable: VARIABLE, evaluar, rachaDelHistorial, esSeco };
