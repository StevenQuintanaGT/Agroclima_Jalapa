'use strict';

/**
 * Punto de entrada del ciclo automático. No es una Cloud Function: lo ejecuta
 * GitHub Actions cada 3 horas (.github/workflows/ciclo-clima.yml, DECISIONES
 * D-37) con el SDK de administración de Firebase, que funciona en el plan
 * gratuito Spark.
 *
 * Los pasos se agregan con sus historias:
 * - adquisición de clima por celda (Etapa 3)
 * - evaluación de umbrales, alertas y envío FCM (Etapa 4)
 * - limpieza de parcelas borradas y cuentas eliminadas (HU-06, Etapa 6)
 */
module.exports = {};
