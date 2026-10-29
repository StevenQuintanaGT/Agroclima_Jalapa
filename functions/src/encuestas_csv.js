'use strict';

/**
 * Encuestas de satisfacción (`encuestas/{uid}`, D-58) a CSV para el trabajo
 * de graduación. Una fila por respuesta, **sin correo ni uid**. El nombre
 * del perfil solo sale si el productor dio permiso; si no, "(sin permiso)".
 * Las etiquetas son las mismas de la app (lib/config/textos.dart).
 */

const ETIQUETAS = {
  p1: { facil: 'Fácil', masOMenos: 'Más o menos', dificil: 'Difícil' },
  p2: { todo: 'Sí, todo', mayoria: 'La mayoría', poco: 'Poco' },
  p3: { si: 'Sí', no: 'No' },
  p4: { mucho: 'Mucho', algo: 'Algo', poco: 'Poco' },
  p5: { si: 'Sí', no: 'No' },
  p6: { si: 'Sí', sinDanio: 'Todavía no ha habido daño', no: 'No' },
  p7: { si: 'Sí', talVez: 'Tal vez', no: 'No' },
};

const MUNICIPIOS = {
  jalapa: 'Jalapa',
  sanPedroPinula: 'San Pedro Pinula',
  sanLuisJilotepeque: 'San Luis Jilotepeque',
  sanManuelChaparron: 'San Manuel Chaparrón',
  sanCarlosAlzatate: 'San Carlos Alzatate',
  monjas: 'Monjas',
  mataquescuintla: 'Mataquescuintla',
};

const CULTIVOS = { maiz: 'Maíz', frijol: 'Frijol', cafe: 'Café', hortalizas: 'Hortalizas' };

const ENCABEZADO = [
  'nombre',
  'municipio',
  'cultivo',
  'p1_facilidad',
  'p2_entiende_avisos',
  'p3_le_llego_aviso',
  'p3_de_que_fue',
  'p4_planificar',
  'p5_hizo_algo',
  'p5_que_hizo',
  'p6_evito_danio',
  'p6_cual',
  'p7_recomendaria',
  'p8_cambiaria',
  'consentimiento',
  'version_app',
  'fecha_respuesta',
];

const DESFASE_MS = -6 * 60 * 60 * 1000;

/** "2026-10-29 14:05" en hora de Guatemala. */
function fechaLocal(fecha) {
  if (!(fecha instanceof Date)) return '';
  return new Date(fecha.getTime() + DESFASE_MS).toISOString().slice(0, 16).replace('T', ' ');
}

function celda(valor) {
  const texto = valor == null ? '' : String(valor);
  return /[",\r\n]/.test(texto) ? `"${texto.replace(/"/g, '""')}"` : texto;
}

/**
 * @param {Array<{datos: object, nombre?: string}>} encuestas `datos` es el
 *   documento (con `fechaRespuesta` como Date) y `nombre` el del perfil.
 * @returns {string} CSV con BOM (para que Excel lea las tildes), filas en CRLF.
 */
function encuestasACsv(encuestas) {
  const filas = [ENCABEZADO];
  for (const { datos, nombre } of encuestas) {
    const opcion = (p) => ETIQUETAS[p][datos[p]] ?? '';
    filas.push([
      datos.consentimiento === true ? nombre ?? '' : '(sin permiso)',
      MUNICIPIOS[datos.municipio] ?? '',
      CULTIVOS[datos.cultivo] ?? '',
      opcion('p1'),
      opcion('p2'),
      opcion('p3'),
      datos.detalleAviso ?? '',
      opcion('p4'),
      opcion('p5'),
      datos.detalleAccion ?? '',
      opcion('p6'),
      datos.detalleDanio ?? '',
      opcion('p7'),
      datos.p8 ?? '',
      datos.consentimiento === true ? 'Sí' : 'No',
      datos.versionApp ?? '',
      fechaLocal(datos.fechaRespuesta),
    ]);
  }
  return '﻿' + filas.map((fila) => fila.map(celda).join(',')).join('\r\n') + '\r\n';
}

module.exports = { encuestasACsv, ENCABEZADO };
