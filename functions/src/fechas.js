'use strict';

/**
 * Fechas en hora de Guatemala (America/Guatemala). Guatemala usa UTC-6 todo
 * el año (sin horario de verano): basta con un desfase fijo. Igual que
 * lib/utilidades/fechas.dart.
 */
const DESFASE_MS = -6 * 60 * 60 * 1000;

/** Id diario yyyyMMdd de condiciones y pronósticos (MODELO_DATOS §1). */
function idDiario(instante) {
  const local = new Date(instante.getTime() + DESFASE_MS);
  const mes = String(local.getUTCMonth() + 1).padStart(2, '0');
  const dia = String(local.getUTCDate()).padStart(2, '0');
  return `${local.getUTCFullYear()}${mes}${dia}`;
}

/** Día anterior a un id yyyyMMdd (para recorrer el historial hacia atrás). */
function diaAnterior(id) {
  const fecha = new Date(Date.UTC(+id.slice(0, 4), +id.slice(4, 6) - 1, +id.slice(6, 8) - 1));
  const mes = String(fecha.getUTCMonth() + 1).padStart(2, '0');
  const dia = String(fecha.getUTCDate()).padStart(2, '0');
  return `${fecha.getUTCFullYear()}${mes}${dia}`;
}

module.exports = { idDiario, diaAnterior };
