'use strict';

/** Viento fuerte: velocidad más alta del día (km/h) (tipoRiesgo `vientoFuerte`): compara `velocidadViento` de cada día del pronóstico. */
const { crearReglaDiaria } = require('./regla_diaria');

module.exports = crearReglaDiaria('velocidadViento');
