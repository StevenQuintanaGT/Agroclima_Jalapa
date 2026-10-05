'use strict';

/** Mucha humedad: humedad relativa promedio del día (%) (tipoRiesgo `humedadAlta`): compara `humedadRelativa` de cada día del pronóstico. */
const { crearReglaDiaria } = require('./regla_diaria');

module.exports = crearReglaDiaria('humedadRelativa');
