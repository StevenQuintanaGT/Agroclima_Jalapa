'use strict';

/**
 * Convierte las franjas de 3 h en un pronóstico por día, agrupadas en hora de
 * Guatemala (DECISIONES D-10). Misma cuenta que lib/servicios/pronostico_diario.dart.
 */
const { DIAS_PRONOSTICO } = require('./config');
const { idDiario } = require('./fechas');

const redondear = (valor) => Math.round(valor * 100) / 100;

/**
 * @param {Array<object>} franjas resultado de cliente.pronostico()
 * @returns {Array<object>} hasta DIAS_PRONOSTICO días (hoy incluido) con los
 *   campos de la Tabla 68, sin fechaConsulta (la pone el servidor).
 */
function agruparPorDia(franjas) {
  const porDia = new Map();
  for (const franja of franjas) {
    const dia = idDiario(franja.fechaHora);
    if (!porDia.has(dia)) porDia.set(dia, []);
    porDia.get(dia).push(franja);
  }
  return [...porDia.keys()]
    .sort()
    .slice(0, DIAS_PRONOSTICO)
    .map((fecha) => resumir(fecha, porDia.get(fecha)));
}

function resumir(fecha, franjas) {
  const valores = (campo) => franjas.map(campo);
  const suma = (lista) => lista.reduce((a, b) => a + b, 0);
  return {
    fecha,
    temperaturaMinima: redondear(Math.min(...valores((f) => f.temperaturaMinima))),
    temperaturaMaxima: redondear(Math.max(...valores((f) => f.temperaturaMaxima))),
    precipitacionHora: redondear(Math.max(...valores((f) => f.lluvia3h / 3))),
    acumuladoDia: redondear(suma(valores((f) => f.lluvia3h))),
    velocidadViento: redondear(Math.max(...valores((f) => f.velocidadViento))),
    humedadRelativa: redondear(suma(valores((f) => f.humedadRelativa)) / franjas.length),
  };
}

module.exports = { agruparPorDia };
