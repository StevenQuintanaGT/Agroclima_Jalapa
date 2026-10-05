'use strict';

/** Calor: temperatura máxima del día (°C) (tipoRiesgo `temperaturaAlta`): compara `temperaturaMaxima` de cada día del pronóstico. */
const { crearReglaDiaria } = require('./regla_diaria');

module.exports = crearReglaDiaria('temperaturaMaxima');
