'use strict';

/**
 * Registro de reglas del motor (patrón Estrategia, UMBRALES.md §4.1): una
 * regla por tipoRiesgo, todas con `evaluar({ pronosticos, historial, umbrales,
 * parcela })`. Agregar un criterio nuevo = un archivo y una línea aquí, sin
 * tocar las demás reglas ni el evaluador.
 */
module.exports = Object.freeze({
  lluviaIntensa: require('./lluvia_intensa'),
  vientoFuerte: require('./viento_fuerte'),
  sequia: require('./sequia'),
  temperaturaBaja: require('./temperatura_baja'),
  temperaturaAlta: require('./temperatura_alta'),
  humedadAlta: require('./humedad_alta'),
});
