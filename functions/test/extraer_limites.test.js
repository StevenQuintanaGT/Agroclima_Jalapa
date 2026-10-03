'use strict';

const { extraer, normalizar } = require('../scripts/extraer-limites-jalapa');

const cuadro = [[[-90, 14], [-89, 14], [-89, 15], [-90, 14]]];

function entidad(nombre) {
  return {
    type: 'Feature',
    properties: { shapeName: nombre },
    geometry: { type: 'Polygon', coordinates: cuadro },
  };
}

const NOMBRES_JALAPA = [
  'Jalapa',
  'San Pedro Pinula',
  'San Luis Jilotepeque',
  'San Manuel Chaparrón',
  'San Carlos Alzatate',
  'Monjas',
  'Mataquescuintla',
];

describe('extraer-limites-jalapa', () => {
  test('normaliza tildes y mayúsculas', () => {
    expect(normalizar(' San Manuel Chaparrón ')).toBe('san manuel chaparron');
  });

  test('deja solo los 7 municipios con el valor de la enumeración', () => {
    const entrada = JSON.stringify({
      type: 'FeatureCollection',
      features: [...NOMBRES_JALAPA.map(entidad), entidad('Acatenango')],
    });
    const resultado = extraer(entrada);
    expect(resultado.features.map((e) => e.properties.municipio)).toEqual([
      'jalapa',
      'sanPedroPinula',
      'sanLuisJilotepeque',
      'sanManuelChaparron',
      'sanCarlosAlzatate',
      'monjas',
      'mataquescuintla',
    ]);
  });

  test('redondea a 5 decimales', () => {
    const entrada = JSON.stringify({
      type: 'FeatureCollection',
      features: NOMBRES_JALAPA.map((n) => ({
        ...entidad(n),
        geometry: {
          type: 'Polygon',
          coordinates: [[[-89.123456789, 14.987654321], [-89, 14], [-90, 14]]],
        },
      })),
    });
    const [primero] = extraer(entrada).features;
    expect(primero.geometry.coordinates[0][0]).toEqual([-89.12346, 14.98765]);
  });

  test('si falta un municipio, avisa en vez de generar un archivo incompleto', () => {
    const entrada = JSON.stringify({
      type: 'FeatureCollection',
      features: NOMBRES_JALAPA.slice(1).map(entidad),
    });
    expect(() => extraer(entrada)).toThrow(/Faltan: \[jalapa\]/);
  });
});
