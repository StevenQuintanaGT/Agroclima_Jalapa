'use strict';

/**
 * Punto de entrada de Cloud Functions (JavaScript, API v2).
 *
 * Las funciones se agregan con sus historias:
 * - adquirirClima (programada, Etapa 3)
 * - borrado en cascada de parcela y eliminarCuenta (HU-06, Etapa 6)
 */
const { initializeApp } = require('firebase-admin/app');

initializeApp();

module.exports = {};
