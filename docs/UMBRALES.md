# Catálogo de umbrales y motor de alertas (Tablas 26 y 31, §5.3–5.4)

Los umbrales **no van en el código**: se guardan en la colección `umbrales` (RNF-19) y se cargan con
`functions/scripts/sembrar-umbrales.js` a partir de `functions/seed/umbrales.json`.
Todos se evalúan sobre el **pronóstico de los próximos 5 días**, no sobre el dato ya ocurrido.

## 1. Catálogo inicial (Tabla 31 de la tesis)

| Variable | Aplica a | Informativa | Preventiva | Crítica |
|---|---|---|---|---|
| Lluvia (intensidad media por hora) | Todos | — | > 15 mm/h | > 30 mm/h |
| Viento | Todos (referencia del café) | — | > 15 km/h | > 30 km/h |
| Sequía (días seguidos < 1 mm) | Todos fuera de etapa sensible | 5 a 10 días | 11 a 15 días | > 15 días |
| Sequía | Maíz en floración; frijol en floración o llenado | — | 5 a 10 días | > 10 días |
| Temperatura mínima | Todos | — | — | ≤ 0 °C (helada) |
| Temperatura mínima | Café | — | < 15 °C | — |
| Temperatura mínima | Frijol | — | < 18 °C | — |
| Temperatura máxima | Café | — | > 30 °C | > 30 °C por 3 días o más |
| Temperatura máxima | Frijol | — | > 28 °C | > 28 °C por 3 días o más |
| Temperatura máxima | Maíz | — | > 35 °C en desarrollo vegetativo | > 35 °C en floración o llenado |
| Humedad relativa | Café | — | > 85 % | — |

Hortalizas: solo criterios generales (lluvia, viento, sequía, helada).
Parcela sin cultivo: solo criterios generales (RN-05).

## 2. Semilla (`functions/seed/umbrales.json`)

```json
[
  {"umbralId":"lluvia_general_preventiva","tipoRiesgo":"lluviaIntensa","variable":"precipitacionHora","cultivo":"","etapa":"","operador":"mayor","valor":15,"duracionDias":1,"nivel":"preventiva","fuente":"Monjo (2010)","vigente":true},
  {"umbralId":"lluvia_general_critica","tipoRiesgo":"lluviaIntensa","variable":"precipitacionHora","cultivo":"","etapa":"","operador":"mayor","valor":30,"duracionDias":1,"nivel":"critica","fuente":"Monjo (2010)","vigente":true},

  {"umbralId":"viento_general_preventiva","tipoRiesgo":"vientoFuerte","variable":"velocidadViento","cultivo":"","etapa":"","operador":"mayor","valor":15,"duracionDias":1,"nivel":"preventiva","fuente":"Moraga (2024)","vigente":true},
  {"umbralId":"viento_general_critica","tipoRiesgo":"vientoFuerte","variable":"velocidadViento","cultivo":"","etapa":"","operador":"mayor","valor":30,"duracionDias":1,"nivel":"critica","fuente":"Moraga (2024)","vigente":true},

  {"umbralId":"sequia_general_informativa","tipoRiesgo":"sequia","variable":"diasSecos","cultivo":"","etapa":"","operador":"mayorIgual","valor":5,"duracionDias":1,"nivel":"informativa","fuente":"MARN El Salvador (s.f.)","vigente":true},
  {"umbralId":"sequia_general_preventiva","tipoRiesgo":"sequia","variable":"diasSecos","cultivo":"","etapa":"","operador":"mayorIgual","valor":11,"duracionDias":1,"nivel":"preventiva","fuente":"MARN El Salvador (s.f.)","vigente":true},
  {"umbralId":"sequia_general_critica","tipoRiesgo":"sequia","variable":"diasSecos","cultivo":"","etapa":"","operador":"mayor","valor":15,"duracionDias":1,"nivel":"critica","fuente":"MARN El Salvador (s.f.)","vigente":true},
  {"umbralId":"sequia_maiz_floracion_preventiva","tipoRiesgo":"sequia","variable":"diasSecos","cultivo":"maiz","etapa":"floracion","operador":"mayorIgual","valor":5,"duracionDias":1,"nivel":"preventiva","fuente":"Fuentes López (2002)","vigente":true},
  {"umbralId":"sequia_maiz_floracion_critica","tipoRiesgo":"sequia","variable":"diasSecos","cultivo":"maiz","etapa":"floracion","operador":"mayor","valor":10,"duracionDias":1,"nivel":"critica","fuente":"Fuentes López (2002)","vigente":true},
  {"umbralId":"sequia_frijol_floracion_preventiva","tipoRiesgo":"sequia","variable":"diasSecos","cultivo":"frijol","etapa":"floracion","operador":"mayorIgual","valor":5,"duracionDias":1,"nivel":"preventiva","fuente":"González (2021)","vigente":true},
  {"umbralId":"sequia_frijol_floracion_critica","tipoRiesgo":"sequia","variable":"diasSecos","cultivo":"frijol","etapa":"floracion","operador":"mayor","valor":10,"duracionDias":1,"nivel":"critica","fuente":"González (2021)","vigente":true},
  {"umbralId":"sequia_frijol_llenado_preventiva","tipoRiesgo":"sequia","variable":"diasSecos","cultivo":"frijol","etapa":"llenado","operador":"mayorIgual","valor":5,"duracionDias":1,"nivel":"preventiva","fuente":"González (2021)","vigente":true},
  {"umbralId":"sequia_frijol_llenado_critica","tipoRiesgo":"sequia","variable":"diasSecos","cultivo":"frijol","etapa":"llenado","operador":"mayor","valor":10,"duracionDias":1,"nivel":"critica","fuente":"González (2021)","vigente":true},

  {"umbralId":"tmin_general_critica","tipoRiesgo":"temperaturaBaja","variable":"temperaturaMinima","cultivo":"","etapa":"","operador":"menorIgual","valor":0,"duracionDias":1,"nivel":"critica","fuente":"Bardales Espinoza et al. (2019)","vigente":true},
  {"umbralId":"tmin_cafe_preventiva","tipoRiesgo":"temperaturaBaja","variable":"temperaturaMinima","cultivo":"cafe","etapa":"","operador":"menor","valor":15,"duracionDias":1,"nivel":"preventiva","fuente":"Moraga (2024)","vigente":true},
  {"umbralId":"tmin_frijol_preventiva","tipoRiesgo":"temperaturaBaja","variable":"temperaturaMinima","cultivo":"frijol","etapa":"","operador":"menor","valor":18,"duracionDias":1,"nivel":"preventiva","fuente":"González (2021)","vigente":true},

  {"umbralId":"tmax_cafe_preventiva","tipoRiesgo":"temperaturaAlta","variable":"temperaturaMaxima","cultivo":"cafe","etapa":"","operador":"mayor","valor":30,"duracionDias":1,"nivel":"preventiva","fuente":"Moraga (2024)","vigente":true},
  {"umbralId":"tmax_cafe_critica","tipoRiesgo":"temperaturaAlta","variable":"temperaturaMaxima","cultivo":"cafe","etapa":"","operador":"mayor","valor":30,"duracionDias":3,"nivel":"critica","fuente":"Moraga (2024); Bardales Espinoza et al. (2019)","vigente":true},
  {"umbralId":"tmax_frijol_preventiva","tipoRiesgo":"temperaturaAlta","variable":"temperaturaMaxima","cultivo":"frijol","etapa":"","operador":"mayor","valor":28,"duracionDias":1,"nivel":"preventiva","fuente":"González (2021)","vigente":true},
  {"umbralId":"tmax_frijol_critica","tipoRiesgo":"temperaturaAlta","variable":"temperaturaMaxima","cultivo":"frijol","etapa":"","operador":"mayor","valor":28,"duracionDias":3,"nivel":"critica","fuente":"González (2021); Bardales Espinoza et al. (2019)","vigente":true},
  {"umbralId":"tmax_maiz_vegetativo_preventiva","tipoRiesgo":"temperaturaAlta","variable":"temperaturaMaxima","cultivo":"maiz","etapa":"desarrolloVegetativo","operador":"mayor","valor":35,"duracionDias":1,"nivel":"preventiva","fuente":"Fuentes López (2002)","vigente":true},
  {"umbralId":"tmax_maiz_floracion_critica","tipoRiesgo":"temperaturaAlta","variable":"temperaturaMaxima","cultivo":"maiz","etapa":"floracion","operador":"mayor","valor":35,"duracionDias":1,"nivel":"critica","fuente":"Fuentes López (2002)","vigente":true},
  {"umbralId":"tmax_maiz_llenado_critica","tipoRiesgo":"temperaturaAlta","variable":"temperaturaMaxima","cultivo":"maiz","etapa":"llenado","operador":"mayor","valor":35,"duracionDias":1,"nivel":"critica","fuente":"Fuentes López (2002)","vigente":true},

  {"umbralId":"humedad_cafe_preventiva","tipoRiesgo":"humedadAlta","variable":"humedadRelativa","cultivo":"cafe","etapa":"","operador":"mayor","valor":85,"duracionDias":1,"nivel":"preventiva","fuente":"Moraga (2024)","vigente":true}
]
```

## 3. Qué umbrales aplican a una parcela

Un umbral aplica si `vigente == true` **y**:
- `cultivo == ""` (general), **o**
- `cultivo == parcela.cultivo` y (`etapa == ""` o `etapa == parcela.etapa`).

Si la parcela no tiene cultivo, solo aplican los generales.

## 4. Algoritmo de evaluación (patrón Estrategia)

Por cada parcela activa, con sus pronósticos de hoy + 4 días (`pronosticos/{yyyyMMdd}`):

1. Agrupar los umbrales aplicables por `tipoRiesgo`. Cada tipo tiene su **regla** (`functions/src/motor/reglas/*.js`),
   con la interfaz `evaluar({ pronosticos, historial, umbrales, parcela }) → [{ nivel, valorEsperado, valorUmbral, fechaEvento, diasConsecutivos? }]`.
2. **Variables diarias** (`precipitacionHora`, `velocidadViento`, `temperaturaMinima`, `temperaturaMaxima`,
   `humedadRelativa`): para cada día se compara el valor con cada umbral según su `operador`.
   Si `duracionDias > 1`, el umbral se cumple en un día solo si ese día y los `duracionDias − 1` días
   **consecutivos** anteriores o siguientes del pronóstico también lo cumplen (racha ≥ duracionDias).
3. **Sequía** (`diasSecos`): día seco = `acumuladoDia < 1 mm` (Zhang et al., 2011). La racha se cuenta
   uniendo los últimos días de `condiciones` (historial, `precipitacion < 1`) con los días del pronóstico.
   `valorEsperado` = días secos consecutivos que se alcanzarían al final de la racha dentro del pronóstico.
   Si no hay historial suficiente, se cuenta solo con lo disponible.
4. **Nivel resultante**: por cada `tipoRiesgo` y día se toma el **nivel más alto** entre todos los umbrales
   cumplidos (generales y específicos). Esto hace que en etapa sensible el criterio específico "adelante"
   un nivel, como pide la tesis, sin anular la helada general en café o frijol.
5. Para cada `tipoRiesgo` se genera como máximo **una alerta por día de evento** con el nivel resultante.
6. `valorEsperado` = valor pronosticado del día; `valorUmbral` = `valor` del umbral que definió el nivel.

Salidas anticipadas (§4.7.2): si el proveedor no respondió o la respuesta no pasó VA-06..VA-08, **no se
evalúa** esa celda en este ciclo. Parcela sin cultivo → solo reglas generales.

## 5. Control de duplicados (RO-03)

Antes de crear una alerta se busca (índice 2) otra con el mismo `parcelaId`, `tipoRiesgo` y `fechaEvento`:
- Si no existe → se crea y se notifica.
- Si existe con el **mismo nivel o mayor** → no se crea nada.
- Si existe con **nivel menor** (el riesgo empeoró) → se crea una nueva alerta con el nivel mayor y se notifica.

Ventana = el día del evento. Constante `VENTANA_DUPLICADOS` en `functions/src/config.js`.

## 6. Envío (preferencias y silencio)

Se notifica por FCM si: `preferencias/{tipoRiesgo}.activa == true` **y** `nivel ≥ nivelMinimo` **y**
no se está en horario de silencio (`silencioDesde`–`silencioHasta`, hora de Guatemala) — **excepto
`critica`, que siempre suena**. Si no se notifica, la alerta igual queda en `alertas` con `notificada: false`.
Se envía a todos los `tokensFcm` del usuario; los tokens inválidos que devuelva FCM se eliminan.

## 7. Mensajes (RNF-14) — `functions/src/mensajes.js`

Formato de la notificación: **título** = palabra del semáforo + nombre de la parcela
(`PELIGRO · Parcela El Tablón`); **cuerpo** = qué va a pasar y cuándo, en lenguaje del campo.

Ejemplos de estilo (se revisarán con productores):
- lluviaIntensa/preventiva: "Va a llover fuerte el jueves. Revise que el agua pueda salir de la parcela."
- sequia/preventiva (maíz en floración): "Van 7 días sin lluvia y el maíz está floreando. Si puede, riegue."
- temperaturaBaja/critica: "Puede caer helada el sábado en la madrugada. Proteja el almácigo."
- temperaturaAlta/critica (café): "Tres días de mucho calor desde el lunes. Dé sombra y riegue si puede."
- humedadAlta/preventiva (café): "Mucha humedad esta semana. Esté pendiente de hongos en las hojas."

`medidaSugerida` sale de una tabla `tipoRiesgo × cultivo` en el mismo archivo.
