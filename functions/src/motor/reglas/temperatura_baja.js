'use strict';

/** Frío y helada: temperatura mínima del día (°C) (tipoRiesgo `temperaturaBaja`): compara `temperaturaMinima` de cada día del pronóstico. */
const { crearReglaDiaria } = require('./regla_diaria');

module.exports = crearReglaDiaria('temperaturaMinima');
