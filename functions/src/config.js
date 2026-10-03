'use strict';

/**
 * Configuración del ciclo automático. Los umbrales NO van aquí: se leen de la
 * colección `umbrales` (RNF-19).
 */
module.exports = Object.freeze({
  // Zona horaria de los ids diarios yyyyMMdd y del horario de silencio.
  ZONA_HORARIA: 'America/Guatemala',

  // Periodicidad del ciclo (DECISIONES D-06): coincide con el pronóstico de 3 h.
  CRON_CICLO: 'every 3 hours',

  // Celda climática: coordenadas redondeadas a 0.05° (DECISIONES D-07).
  TAMANO_CELDA_GRADOS: 0.05,

  // Tiempo máximo por consulta a OpenWeather (RNF-07) y reintentos del ciclo.
  ESPERA_CLIMA_MS: 5000,
  REINTENTOS_CLIMA: 3,

  // Días de pronóstico que evalúa el motor (hoy + 4).
  DIAS_PRONOSTICO: 5,

  // Días de historial de condiciones para contar la racha de sequía.
  DIAS_HISTORIAL_SEQUIA: 20,

  // Control de duplicados (UMBRALES.md §5): la ventana es el día del evento.
  VENTANA_DUPLICADOS: 'dia',

  // Día seco: acumulado menor a 1 mm (Zhang et al., 2011).
  UMBRAL_DIA_SECO_MM: 1,

  // Rangos posibles para la región (VA-07, REQUISITOS §7).
  RANGOS_VALIDOS: Object.freeze({
    temperatura: Object.freeze({ min: -5, max: 45 }),
    humedad: Object.freeze({ min: 0, max: 100 }),
    lluviaMmHora: Object.freeze({ min: 0, max: 200 }),
    vientoKmHora: Object.freeze({ min: 0, max: 200 }),
  }),

  // Valores permitidos en Firestore (MODELO_DATOS.md §2 y §3).
  TIPOS_RIESGO: Object.freeze([
    'lluviaIntensa',
    'vientoFuerte',
    'sequia',
    'temperaturaBaja',
    'temperaturaAlta',
    'humedadAlta',
  ]),
  NIVELES: Object.freeze(['informativa', 'preventiva', 'critica']),
  CULTIVOS: Object.freeze(['maiz', 'frijol', 'cafe', 'hortalizas']),
  ETAPAS: Object.freeze([
    'siembra',
    'desarrolloVegetativo',
    'floracion',
    'llenado',
    'cosecha',
  ]),
  VARIABLES: Object.freeze([
    'precipitacionHora',
    'velocidadViento',
    'diasSecos',
    'temperaturaMinima',
    'temperaturaMaxima',
    'humedadRelativa',
  ]),
  OPERADORES: Object.freeze(['mayor', 'mayorIgual', 'menor', 'menorIgual']),
});
