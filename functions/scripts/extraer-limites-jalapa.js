'use strict';

/**
 * Genera assets/geo/jalapa_municipios.geojson (DECISIONES D-11) a partir de
 * los municipios de Guatemala de geoBoundaries (gbOpen GTM ADM2, simplificado):
 *   https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/GTM/ADM2/geoBoundaries-GTM-ADM2_simplified.geojson
 * Fuente original: CONRED / OCHA (2021). Licencia CC BY 3.0 IGO (citar la fuente).
 *
 * Uso:  node functions/scripts/extraer-limites-jalapa.js <entrada.geojson> [salida.geojson]
 *
 * Deja solo los 7 municipios del departamento de Jalapa, con la propiedad
 * `municipio` igual al valor de la enumeración (MODELO_DATOS §2), y redondea
 * las coordenadas a 5 decimales (~1 m) para reducir el tamaño.
 */
const fs = require('node:fs');
const path = require('node:path');

const MUNICIPIOS = {
  'jalapa': 'jalapa',
  'san pedro pinula': 'sanPedroPinula',
  'san luis jilotepeque': 'sanLuisJilotepeque',
  'san manuel chaparron': 'sanManuelChaparron',
  'san carlos alzatate': 'sanCarlosAlzatate',
  'monjas': 'monjas',
  'mataquescuintla': 'mataquescuintla',
};

const DECIMALES = 5;

function normalizar(nombre) {
  return nombre
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .trim();
}

function redondear(coordenadas) {
  if (typeof coordenadas[0] === 'number') {
    const factor = 10 ** DECIMALES;
    return coordenadas.map((v) => Math.round(v * factor) / factor);
  }
  return coordenadas.map(redondear);
}

function extraer(entrada) {
  const datos = JSON.parse(entrada);
  const entidades = [];
  for (const entidad of datos.features) {
    const nombre = entidad.properties.shapeName;
    const valor = MUNICIPIOS[normalizar(nombre)];
    if (!valor) continue;
    entidades.push({
      type: 'Feature',
      properties: { municipio: valor, nombre },
      geometry: {
        type: entidad.geometry.type,
        coordinates: redondear(entidad.geometry.coordinates),
      },
    });
  }
  const encontrados = entidades.map((e) => e.properties.municipio);
  const faltan = Object.values(MUNICIPIOS).filter((m) => !encontrados.includes(m));
  const repetidos = encontrados.filter((m, i) => encontrados.indexOf(m) !== i);
  if (faltan.length || repetidos.length) {
    throw new Error(
      `Revise los nombres. Faltan: [${faltan}] · Repetidos: [${repetidos}]`,
    );
  }
  return {
    type: 'FeatureCollection',
    fuente:
      'geoBoundaries gbOpen GTM ADM2 (CONRED / OCHA 2021), CC BY 3.0 IGO',
    features: entidades,
  };
}

if (require.main === module) {
  const [entrada, salida] = process.argv.slice(2);
  if (!entrada) {
    console.error('Uso: node extraer-limites-jalapa.js <entrada.geojson> [salida.geojson]');
    process.exit(1);
  }
  const destino =
    salida ?? path.join(__dirname, '..', '..', 'assets', 'geo', 'jalapa_municipios.geojson');
  const resultado = extraer(fs.readFileSync(entrada, 'utf8'));
  fs.writeFileSync(destino, JSON.stringify(resultado));
  const kb = (fs.statSync(destino).size / 1024).toFixed(1);
  for (const e of resultado.features) {
    console.log(`  ${e.properties.municipio.padEnd(20)} ${e.geometry.type}`);
  }
  console.log(`${resultado.features.length} municipios → ${destino} (${kb} KB)`);
}

module.exports = { extraer, normalizar };
