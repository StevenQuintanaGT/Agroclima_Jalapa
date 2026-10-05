'use strict';

/**
 * Textos de las alertas y de la notificación (RNF-14, UMBRALES.md §7). En
 * lenguaje del campo: qué va a pasar, cuándo y qué conviene hacer. Se
 * revisarán con productores (RC-01): todos los textos están en este archivo.
 *
 * Forma de la notificación (pantalla 24 del diseño, DECISIONES D-47):
 *   título  "PELIGRO: puede caer helada en La Joya"
 *   cuerpo  "Mañana en la madrugada puede bajar a -1 °C. Toque para ver qué hacer."
 */
const { idDiario, diaDeSemana } = require('./fechas');

/** Palabra del semáforo (DISENO_UI §2). */
const PALABRA = Object.freeze({ informativa: 'NORMAL', preventiva: 'PRECAUCIÓN', critica: 'PELIGRO' });

const DIAS = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];

/**
 * Qué conviene hacer, por riesgo y cultivo ('' = cualquier cultivo).
 * `corta` va al final de la notificación; `larga` es la `medidaSugerida`.
 */
const MEDIDAS = Object.freeze({
  lluviaIntensa: {
    '': {
      corta: 'Revise que el agua pueda salir de la parcela.',
      larga: 'Limpie zanjas y salidas de agua para que no se encharque. No abone ni fumigue ese día: la lluvia lo lava.',
    },
    cafe: {
      corta: 'Revise que el agua pueda salir del cafetal.',
      larga: 'Limpie las cunetas del cafetal y revise los terrenos con pendiente. No abone ese día: la lluvia lo lava.',
    },
    hortalizas: {
      corta: 'Abra salidas de agua entre los surcos.',
      larga: 'Abra salidas de agua entre los surcos y, si puede, cubra los almácigos. No fumigue ese día.',
    },
  },
  vientoFuerte: {
    '': {
      corta: 'No fumigue.',
      larga: 'No fumigue ni abone con viento: se pierde el producto. Amarre o apuntale lo que pueda caerse.',
    },
    maiz: {
      corta: 'No fumigue.',
      larga: 'No fumigue ese día. Si el maíz está alto, aporque para que no se acame.',
    },
    cafe: {
      corta: 'No fumigue.',
      larga: 'No fumigue ese día. Revise la sombra y las ramas que puedan caer sobre el cafetal.',
    },
  },
  sequia: {
    '': {
      corta: 'Si puede, riegue.',
      larga: 'Riegue en las horas frescas (temprano o al atardecer) y cubra el suelo con rastrojo para que guarde la humedad.',
    },
    maiz: {
      corta: 'Si puede, riegue el maíz.',
      larga: 'El maíz sufre más sin agua cuando está floreando o llenando el grano. Riegue en las horas frescas y cubra el suelo con rastrojo.',
    },
    frijol: {
      corta: 'Si puede, riegue el frijol.',
      larga: 'El frijol sufre más sin agua cuando está floreando o llenando la vaina. Riegue en las horas frescas y cubra el suelo con rastrojo.',
    },
  },
  temperaturaBaja: {
    '': {
      corta: 'Toque para ver qué hacer.',
      larga: 'Proteja los almácigos y las plantas pequeñas con plástico o rastrojo durante la noche. Riegue por la tarde: el suelo húmedo guarda mejor el calor.',
    },
    cafe: {
      corta: 'Proteja el almácigo.',
      larga: 'Proteja el almácigo y las plantas nuevas del cafetal durante la noche. Con frío el café crece más despacio.',
    },
    frijol: {
      corta: 'Proteja las plantas pequeñas.',
      larga: 'El frijol se atrasa con noches frías. Proteja las plantas pequeñas y, si aún no ha sembrado, espere a que pase el frío.',
    },
  },
  temperaturaAlta: {
    '': {
      corta: 'Riegue si puede.',
      larga: 'Riegue temprano o al atardecer y evite los trabajos pesados en las horas de más sol.',
    },
    cafe: {
      corta: 'Dé sombra y riegue si puede.',
      larga: 'Revise la sombra del cafetal y riegue si puede. El calor fuerte puede botar la flor y el grano tierno.',
    },
    frijol: {
      corta: 'Riegue en las horas frescas.',
      larga: 'Riegue en las horas frescas. Con mucho calor el frijol puede botar la flor.',
    },
    maiz: {
      corta: 'Riegue si puede.',
      larga: 'Riegue si puede, sobre todo si el maíz está floreando: el calor fuerte seca el polen.',
    },
  },
  humedadAlta: {
    '': {
      corta: 'Esté pendiente de hongos en las hojas.',
      larga: 'Revise las hojas por manchas de hongos. Si puede, deje que circule el aire entre las plantas.',
    },
    cafe: {
      corta: 'Esté pendiente de hongos en las hojas.',
      larga: 'Revise las hojas por manchas de roya u ojo de gallo. Si puede, regule la sombra para que circule el aire.',
    },
  },
});

const redondo = (valor) => String(Math.round(valor));
const mayuscula = (texto) => texto.charAt(0).toUpperCase() + texto.slice(1);

/** "hoy", "mañana" o "el jueves" (los eventos caen dentro de los próximos 5 días). */
function cuando(fechaEvento, ahora) {
  const hoy = idDiario(ahora);
  if (fechaEvento <= hoy) return 'hoy';
  if (fechaEvento === idDiario(new Date(ahora.getTime() + 24 * 3600 * 1000))) return 'mañana';
  return `el ${DIAS[diaDeSemana(fechaEvento)]}`;
}

const esHelada = (riesgo) => riesgo.tipoRiesgo === 'temperaturaBaja' && riesgo.valorUmbral <= 0;

/** Riesgo en pocas palabras, para el título. */
function nombreRiesgo(riesgo) {
  switch (riesgo.tipoRiesgo) {
    case 'lluviaIntensa':
      return 'lluvia fuerte';
    case 'vientoFuerte':
      return 'viento fuerte';
    case 'sequia':
      return 'días sin lluvia';
    case 'temperaturaBaja':
      return esHelada(riesgo) ? 'puede caer helada' : 'frío';
    case 'temperaturaAlta':
      return 'mucho calor';
    case 'humedadAlta':
      return 'mucha humedad';
    default:
      return 'riesgo de clima';
  }
}

/** Qué va a pasar y cuándo (primera frase del mensaje). */
function situacion(riesgo, ahora) {
  const dia = cuando(riesgo.fechaEvento, ahora);
  const valor = redondo(riesgo.valorEsperado);
  switch (riesgo.tipoRiesgo) {
    case 'lluviaIntensa':
      return `${mayuscula(dia)} se esperan hasta ${valor} mm de lluvia por hora.`;
    case 'vientoFuerte':
      return `${mayuscula(dia)}, viento de hasta ${valor} km/h.`;
    case 'sequia':
      return `Se esperan ${riesgo.diasConsecutivos ?? valor} días seguidos sin lluvia.`;
    case 'temperaturaBaja':
      return esHelada(riesgo)
        ? `${mayuscula(dia)} en la madrugada puede bajar a ${valor} °C.`
        : `${mayuscula(dia)} en la madrugada se esperan ${valor} °C.`;
    case 'temperaturaAlta':
      return riesgo.diasConsecutivos > 1
        ? `Desde ${cuando(riesgo.inicioRacha ?? riesgo.fechaEvento, ahora)}, ${riesgo.diasConsecutivos} días seguidos con más de ${redondo(riesgo.valorUmbral)} °C.`
        : `${mayuscula(dia)} se esperan ${valor} °C.`;
    case 'humedadAlta':
      return `${mayuscula(dia)} la humedad llegará a ${valor} %.`;
    default:
      return `${mayuscula(dia)} hay riesgo de clima.`;
  }
}

function medida(tipoRiesgo, cultivo) {
  const porCultivo = MEDIDAS[tipoRiesgo] ?? {};
  return porCultivo[cultivo] ?? porCultivo[''] ?? { corta: 'Toque para ver qué hacer.', larga: '' };
}

/**
 * Textos de una alerta.
 * @param {{tipoRiesgo: string, nivel: string, valorEsperado: number, valorUmbral: number,
 *   fechaEvento: string, diasConsecutivos?: number, parcelaNombre: string, cultivo?: string}} riesgo
 * @param {Date} ahora
 * @returns {{titulo: string, mensaje: string, medidaSugerida: string}}
 */
function textosAlerta(riesgo, ahora) {
  const { corta, larga } = medida(riesgo.tipoRiesgo, riesgo.cultivo ?? '');
  return {
    titulo: `${PALABRA[riesgo.nivel]}: ${nombreRiesgo(riesgo)} en ${riesgo.parcelaNombre}`,
    mensaje: `${situacion(riesgo, ahora)} ${corta}`,
    medidaSugerida: larga,
  };
}

module.exports = { textosAlerta, cuando, PALABRA, MEDIDAS };
