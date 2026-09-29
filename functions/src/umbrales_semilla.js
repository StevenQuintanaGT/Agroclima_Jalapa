'use strict';

const config = require('./config');

const CAMPOS_OBLIGATORIOS = [
  'umbralId',
  'tipoRiesgo',
  'variable',
  'operador',
  'valor',
  'nivel',
  'fuente',
  'vigente',
];

/**
 * Revisa que un umbral cumpla la Tabla 70 (MODELO_DATOS.md §3).
 * Devuelve la lista de problemas encontrados (vacía si está bien).
 */
function validarUmbral(umbral) {
  const problemas = [];
  for (const campo of CAMPOS_OBLIGATORIOS) {
    if (umbral[campo] === undefined || umbral[campo] === null) {
      problemas.push(`falta ${campo}`);
    }
  }
  if (!config.TIPOS_RIESGO.includes(umbral.tipoRiesgo)) {
    problemas.push(`tipoRiesgo inválido: ${umbral.tipoRiesgo}`);
  }
  if (!config.VARIABLES.includes(umbral.variable)) {
    problemas.push(`variable inválida: ${umbral.variable}`);
  }
  if (!config.OPERADORES.includes(umbral.operador)) {
    problemas.push(`operador inválido: ${umbral.operador}`);
  }
  if (!config.NIVELES.includes(umbral.nivel)) {
    problemas.push(`nivel inválido: ${umbral.nivel}`);
  }
  if (umbral.cultivo && !config.CULTIVOS.includes(umbral.cultivo)) {
    problemas.push(`cultivo inválido: ${umbral.cultivo}`);
  }
  if (umbral.etapa && !config.ETAPAS.includes(umbral.etapa)) {
    problemas.push(`etapa inválida: ${umbral.etapa}`);
  }
  if (typeof umbral.valor !== 'number') {
    problemas.push('valor debe ser número');
  }
  const duracion = umbral.duracionDias ?? 1;
  if (!Number.isInteger(duracion) || duracion < 1) {
    problemas.push('duracionDias debe ser entero ≥ 1');
  }
  return problemas;
}

/** Valida el catálogo completo: cada umbral y que los ids no se repitan. */
function validarCatalogo(umbrales) {
  const problemas = [];
  const ids = new Set();
  for (const umbral of umbrales) {
    for (const problema of validarUmbral(umbral)) {
      problemas.push(`${umbral.umbralId ?? '(sin id)'}: ${problema}`);
    }
    if (ids.has(umbral.umbralId)) {
      problemas.push(`${umbral.umbralId}: id repetido`);
    }
    ids.add(umbral.umbralId);
  }
  return problemas;
}

module.exports = { validarUmbral, validarCatalogo };
