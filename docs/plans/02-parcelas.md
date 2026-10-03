# Plan 02 — Gestión geoespacial de parcelas (MOD-02 · EP-02) · Etapa 2

> **Actualización D-37 (2026-10-03):** sin plan Blaze. Mapas con `flutter_map` + Esri (sin clave); el ciclo
> de `functions/` lo ejecuta GitHub Actions cada 3 h con `firebase-admin` (no Cloud Functions, Cloud Scheduler
> ni Secret Manager). Donde este plan diga `onSchedule`, `onDocumentDeleted`, `defineSecret`, "desplegar
> funciones" o Google Maps, aplicar `DECISIONES.md` D-37.

Historias: **HU-03** Mapa (8) · **HU-04** Ubicación del teléfono (3) · **HU-05** Nombre, cultivo y etapa (5) ·
**HU-06** Listado, edición y eliminación (5).
Pantallas: 10–13 registro en 4 pasos, 14 mis parcelas, 15 detalle/borrar, 16 vacío.

## Componentes
- **CO-03** Mapa de selección (`GoogleMap` centrado en Jalapa, marcador arrastrable, botón "Usar mi ubicación").
- **CO-04** Formulario en 4 pasos con `BarraProgresoPasos` (RNF-12).
- **CO-05** `ValidacionGeografica`: `Municipio? municipioDe(double lat, double lon)` usando
  `assets/geo/jalapa_municipios.geojson` y punto en polígono (ray casting). `null` = fuera de Jalapa.
- **CO-06** `ParcelasRepositorio`: `crear`, `Stream<List<Parcela>> listar(uid)`, `obtener(id)`, `actualizar`, `eliminar`.
- `CeldaClima.calcular(lat, lon)` (D-07). `UbicacionServicio` (geolocator + permisos).

## Los 4 pasos (una decisión por paso)
1. **Nombre + municipio**: campo nombre (VA-02: no vacío ni repetido en la cuenta) y 7 botones de municipio
   visibles a la vez.
2. **Cultivo + "¿Cómo va el cultivo?"**: 4 botones de cultivo (D-01) y 5 de etapa (D-02). Se permite
   "Todavía no he sembrado" → cultivo y etapa vacíos (solo alertas generales, RN-05).
3. **Mapa**: centrado en el municipio elegido; marcador por toque/arrastre o "Usar mi ubicación" (HU-04).
   Muestra coordenadas (4 decimales), altura (opcional, editable) y tamaño en manzanas/hectáreas (VA-03).
   Al confirmar: `ValidacionGeografica`. Fuera de Jalapa → aviso y no deja avanzar (VA-01).
   Si el punto cae en **otro municipio** que el del paso 1 → se avisa y se actualiza al municipio real.
4. **Revisión**: cada dato con botón "Cambiar" que vuelve a su paso. "Guardar parcela".

Al guardar: `usuarioId = uid`, `ubicacion = GeoPoint` redondeado a 6 decimales (≥ 4), `celdaClima`,
`activa = true`, `fechaRegistro` y `fechaActualizacion = serverTimestamp()`.
El guardado funciona sin señal (queda pendiente y se sincroniza) y avisa "Guardada. Se enviará cuando haya señal." (RNF-16).

## Listado y edición (HU-06)
- Tarjeta: nombre, municipio, cultivo, temperatura actual (si hay dato) y `ChipSemaforo` con el nivel más
  alto de las alertas activas de esa parcela.
- Deslizar → Editar / Borrar. Editar reutiliza los pasos. Si cambian coordenadas se recalcula `celdaClima`;
  si cambia cultivo/etapa, el próximo ciclo evalúa con los nuevos umbrales (Tabla 45, mantenimiento).
- Borrar: diálogo "Se borrará la parcela y todo su historial." · "Sí, borrar" / "No, quedarme".
  La app borra el documento; el ciclo (`limpiarParcelasBorradas`, D-37/D-38) borra subcolecciones y alertas.
- Vacío (16): ilustración + "Registre su primera parcela".

## Límites de Jalapa (D-11)
Obtener polígonos ADM2 de Guatemala (geoBoundaries u otra fuente abierta), filtrar los 7 municipios de Jalapa,
simplificar (~100 KB máximo) y guardar con propiedad `municipio` usando los valores de la enumeración.
Si no hay acceso a internet para descargarlo, **pedírselo a Steven**; no inventar coordenadas.

## Criterios de aceptación
- Normal: registrar parcela por mapa en ≤ 4 pasos; aparece en la lista.
- Alterno: registrar con "Usar mi ubicación" estando en el terreno.
- Error: sin permiso de ubicación → se explica y se puede seguir con el mapa; mapa no carga → queda
  "Usar mi ubicación"; punto fuera de Jalapa → bloqueado; nombre repetido → pide otro; área 0 o texto → inválido;
  sin señal → se guarda pendiente.

## Pruebas
Unitarias: validador geográfico (puntos conocidos dentro de cada municipio y fuera), celda, VA-02/VA-03.
Widget: navegación entre pasos y botón "Cambiar". Reglas: parcela ajena inaccesible.
