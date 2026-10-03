'use strict';

/**
 * FACHADA de OpenWeather para el ciclo (plan gratuito, D-09): arma las
 * peticiones, reintenta con espera creciente, traduce al dominio y valida
 * (VA-06, VA-07). El resto del ciclo nunca ve el JSON del proveedor.
 * Misma traducción que lib/servicios/openweather_cliente.dart.
 */
const { ESPERA_CLIMA_MS, REINTENTOS_CLIMA } = require('./config');
const { enRango } = require('./validacion');

const BASE = 'https://api.openweathermap.org/data/2.5';

class ErrorClima extends Error {
  /**
   * @param {'sinConexion'|'tiempoAgotado'|'claveInvalida'|'limiteAlcanzado'|
   *   'servicioCaido'|'respuestaInvalida'} motivo
   */
  constructor(motivo) {
    super(`No se pudo obtener el clima: ${motivo}`);
    this.name = 'ErrorClima';
    this.motivo = motivo;
  }
}

/** Errores que pueden pasar con esperar: se reintentan. */
const PASAJEROS = new Set(['sinConexion', 'tiempoAgotado', 'limiteAlcanzado', 'servicioCaido']);

const dormir = (ms) => new Promise((resolver) => setTimeout(resolver, ms));

/**
 * @param {object} opciones
 * @param {string} opciones.clave secreto OPENWEATHER_KEY
 * @param {typeof fetch} [opciones.pedirHttp] para pruebas
 * @param {(ms: number) => Promise<void>} [opciones.esperar] para pruebas
 */
function crearCliente({ clave, pedirHttp = fetch, esperar = dormir } = {}) {
  if (!clave) throw new Error('Falta la clave de OpenWeather (OPENWEATHER_KEY).');

  async function pedirUnaVez(ruta, latitud, longitud) {
    const parametros = new URLSearchParams({
      lat: latitud.toFixed(4),
      lon: longitud.toFixed(4),
      units: 'metric',
      lang: 'es',
      appid: clave,
    });
    let respuesta;
    try {
      respuesta = await pedirHttp(`${BASE}${ruta}?${parametros}`, {
        signal: AbortSignal.timeout(ESPERA_CLIMA_MS),
      });
    } catch (error) {
      const agotado = error?.name === 'TimeoutError' || error?.name === 'AbortError';
      throw new ErrorClima(agotado ? 'tiempoAgotado' : 'sinConexion');
    }
    if (respuesta.status === 401) throw new ErrorClima('claveInvalida');
    if (respuesta.status === 429) throw new ErrorClima('limiteAlcanzado');
    if (!respuesta.ok) throw new ErrorClima('servicioCaido');
    try {
      return await respuesta.json();
    } catch {
      throw new ErrorClima('respuestaInvalida');
    }
  }

  // Reintentos con espera creciente (1 s, 2 s, 4 s), solo en la nube.
  async function pedir(ruta, latitud, longitud) {
    for (let intento = 0; ; intento++) {
      try {
        return await pedirUnaVez(ruta, latitud, longitud);
      } catch (error) {
        if (!PASAJEROS.has(error.motivo) || intento >= REINTENTOS_CLIMA) throw error;
        await esperar(1000 * 2 ** intento);
      }
    }
  }

  return {
    /** Current Weather 2.5: clima de este momento. */
    async actual(latitud, longitud) {
      const clima = traducirActual(await pedir('/weather', latitud, longitud));
      if (!clima) throw new ErrorClima('respuestaInvalida');
      return clima;
    },
    /** 5 day / 3 hour Forecast 2.5: franjas de 3 h en orden. */
    async pronostico(latitud, longitud) {
      const franjas = traducirPronostico(await pedir('/forecast', latitud, longitud));
      if (!franjas) throw new ErrorClima('respuestaInvalida');
      return franjas;
    },
  };
}

const numero = (valor) => (typeof valor === 'number' && Number.isFinite(valor) ? valor : null);
const instante = (segundos) => new Date(segundos * 1000);
const kmPorHora = (metrosPorSegundo) => metrosPorSegundo * 3.6;

function condicion(json) {
  const primera = Array.isArray(json.weather) ? json.weather[0] : null;
  return { codigoClima: numero(primera?.id) ?? 800, descripcion: primera?.description ?? '' };
}

/** `/weather` a objeto del dominio; null si falta algo (VA-06) o es imposible (VA-07). */
function traducirActual(json) {
  const dt = numero(json?.dt);
  const temperatura = numero(json?.main?.temp);
  const humedadRelativa = numero(json?.main?.humidity);
  const viento = numero(json?.wind?.speed);
  if (dt == null || temperatura == null || humedadRelativa == null || viento == null) return null;
  const lluviaUltimaHora = numero(json.rain?.['1h']) ?? 0;
  const velocidadViento = kmPorHora(viento);
  if (!enRango({ temperatura, humedadRelativa, velocidadViento, lluviaPorHora: lluviaUltimaHora })) {
    return null;
  }
  return {
    fechaHora: instante(dt),
    temperatura,
    sensacionTermica: numero(json.main.feels_like) ?? temperatura,
    humedadRelativa,
    lluviaUltimaHora,
    velocidadViento,
    ...condicion(json),
  };
}

/** `/forecast` a franjas en orden; null si alguna está incompleta o es imposible. */
function traducirPronostico(json) {
  const lista = json?.list;
  if (!Array.isArray(lista) || lista.length === 0) return null;
  const franjas = [];
  for (const elemento of lista) {
    const franja = traducirFranja(elemento);
    if (!franja) return null;
    franjas.push(franja);
  }
  return franjas.sort((a, b) => a.fechaHora - b.fechaHora);
}

function traducirFranja(json) {
  const dt = numero(json?.dt);
  const temperatura = numero(json?.main?.temp);
  const humedadRelativa = numero(json?.main?.humidity);
  const viento = numero(json?.wind?.speed);
  if (dt == null || temperatura == null || humedadRelativa == null || viento == null) return null;
  const temperaturaMinima = numero(json.main.temp_min) ?? temperatura;
  const temperaturaMaxima = numero(json.main.temp_max) ?? temperatura;
  const lluvia3h = numero(json.rain?.['3h']) ?? 0;
  const velocidadViento = kmPorHora(viento);
  const valida =
    enRango({
      temperatura: temperaturaMinima,
      humedadRelativa,
      velocidadViento,
      lluviaPorHora: lluvia3h / 3,
    }) && enRango({ temperatura: temperaturaMaxima, humedadRelativa, velocidadViento });
  if (!valida) return null;
  return {
    fechaHora: instante(dt),
    temperatura,
    temperaturaMinima,
    temperaturaMaxima,
    humedadRelativa,
    lluvia3h,
    velocidadViento,
    probabilidadLluvia: numero(json.pop) ?? 0,
    ...condicion(json),
  };
}

module.exports = { crearCliente, ErrorClima, traducirActual, traducirPronostico };
