'use strict';

/** Lluvia fuerte: intensidad media por hora más alta del día (tipoRiesgo `lluviaIntensa`): compara `precipitacionHora` de cada día del pronóstico. */
const { crearReglaDiaria } = require('./regla_diaria');

module.exports = crearReglaDiaria('precipitacionHora');
