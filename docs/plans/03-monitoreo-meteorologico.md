# Plan 03 — Monitoreo meteorológico (MOD-03 · EP-03) · Etapas 3 y 5

Historias: **HU-07** Condiciones actuales (5) · **HU-15** Sin conexión (8) · **HU-08** Pronóstico (5) —
Etapa 3 · **HU-09** Capa de precipitación (8) — Etapa 5.
Pantallas: 17/18 panel principal, 19 detalle de pronóstico, 20 mapa del clima, 32 sin conexión, 33 carga, 34 error.

## 1. Dos caminos para el dato

| | Ciclo automático (nube) | Consulta puntual (app) |
|---|---|---|
| Quién | Función programada `adquirirClima` cada 3 h (D-06) | `ClimaRepositorio` al abrir el panel o "Actualizar" |
| Clave | Secreto `OPENWEATHER_KEY` | `OPENWEATHER_API_KEY` (dart-define) |
| Escribe | `pronosticos/{fecha}` (5 días) y `condiciones/{hoy}` con `origen: ciclo` | `condiciones/{hoy}` con `origen: consulta`; pronóstico horario solo en caché local (D-12) |
| Llamadas | 2 por **celda** con parcelas activas (actual + forecast) | 1–2 por parcela abierta, solo si el dato caducó |

## 2. Celda climática (RN-06, D-07)
`celdaClima` se calcula al crear/editar la parcela. El ciclo agrupa parcelas activas por celda, consulta el
centro de la celda **una vez** y escribe el mismo resultado en todas las parcelas de esa celda (RT-02).
Registrar en el log del ciclo: celdas consultadas, llamadas hechas, errores.

## 3. Cliente OpenWeather (Fachada) — `servicios/openweather_cliente.dart` y `functions/src/openweather.js`
- `GET https://api.openweathermap.org/data/2.5/weather?lat&lon&units=metric&lang=es&appid`
  → temperatura (`main.temp`), humedad (`main.humidity`), lluvia (`rain.1h` o 0), viento (`wind.speed × 3.6`), `dt`.
- `GET https://api.openweathermap.org/data/2.5/forecast?lat&lon&units=metric&lang=es&appid`
  → 40 franjas de 3 h; agrupar por día en hora de Guatemala según D-10.
- Tiempo máximo 5 s (RNF-07); reintentos con espera creciente solo en la nube.
- Validar antes de guardar: VA-06 (campos completos), VA-07 (rangos), VA-08 (`dt` posterior al último guardado).
- Traduce a los modelos del dominio; nunca expone JSON crudo a otras capas.

## 4. Repositorio con caché primero (RNF-08, HU-15)
```
obtenerCondiciones(parcela):
  local = leer condiciones/{hoy} (Firestore, acepta caché)
  si local existe y (ahora - local.fechaHora) < vigencia (D-08) → devolver Resultado(local, vigente: true)
  si no hay conexión → devolver Resultado(local, vigente: false)  // o vacío con estado "sin datos aún"
  intentar red (≤ 5 s):
     ok  → validar, guardar condiciones/{hoy} (origen: consulta), devolver vigente
     falla → devolver Resultado(local, vigente: false, error amigable)
```
Lo mismo para el pronóstico horario (caché en `shared_preferences` por `celdaClima`).
Los próximos días se leen de `pronosticos` ordenados por id (solo hoy en adelante).

## 5. Panel principal (pantalla 17/18)
Orden fijo: (1) riesgo del día con `ChipSemaforo` y banner de la alerta activa más grave;
(2) temperatura actual a 64 sp con frase ("Sol fuerte", "Nublado"); (3) humedad, viento, lluvia (+ sensación,
salida/puesta del sol si hay espacio: seis métricas del mockup); (4) por horas; (5) próximos días;
(6) consejo corto; (7) línea "Datos de OpenWeather · actualizado hace X" y `AvisoApoyo`.
Selector de parcela arriba si hay más de una. Deslizar hacia abajo = actualizar.
Estados: esqueleto (33) mientras carga; `AvisoNoVigente` con aspecto apagado y "Intentar de nuevo" (32);
error de servicio con causa probable (34).

## 6. Detalle de pronóstico (19)
Curva de temperatura (fl_chart), barras de lluvia por franja con frase que la interpreta
("lluvia ligera" < 2.5 mm/h, "lluvia moderada" 2.5–15, "lluvia fuerte" > 15), viento, humedad, sol.

## 7. Mapa del clima (20, HU-09)
`GoogleMap` con pines de las parcelas del usuario. Capas como `TileOverlay` desde
`https://tile.openweathermap.org/map/{capa}/{z}/{x}/{y}.png?appid=` con botones con ícono y nombre:
Lluvia (`precipitation_new`), Nubes (`clouds_new`), Calor (`temp_new`), Viento (`wind_new`).
**Una capa a la vez** y solo cuando el usuario la activa (RT-04). Con ahorro de datos, capas desactivadas
hasta que el usuario acepte. Leyenda "Qué significan los colores". Si la capa falla: mapa sin capa + aviso.

## 8. Función `adquirirClima` (CMP-08) — `functions/src/adquisicion.js`
`onSchedule({ schedule: 'every 3 hours', timeZone: 'America/Guatemala', secrets: [OPENWEATHER_KEY] })`
1. Leer parcelas `activa == true`; agrupar por `celdaClima`.
2. Por celda: current + forecast (respetar 60/min con pausa si hay muchas celdas).
3. Validar; si falla la celda → registrar y seguir con la siguiente (salida anticipada, sin alertas).
4. Escribir en lote (`BulkWriter`) `condiciones/{hoy}` y `pronosticos/{fecha}` de cada parcela de la celda.
5. Llamar al motor (`plans/04`) con las parcelas actualizadas.

## Criterios de aceptación
- Normal: el panel muestra las 4 variables con hora de actualización en ≤ 5 s.
- Alterno: con dato vigente en caché no se llama a la red (RNF-11).
- Error: modo avión → últimos datos apagados con fecha; OpenWeather caído → dato guardado + aviso; sin
  ningún dato previo → estado "Todavía no hay datos de esta parcela" con "Intentar de nuevo".
