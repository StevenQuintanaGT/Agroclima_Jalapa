# Plan 05 — Historial y reportes (MOD-05 · EP-05) + Perfil · Etapas 5 y 6

Historias: **HU-14** Historial de alertas (5) · **HU-13** Condiciones anteriores (8) — Etapa 5 ·
**HU-16** Resumen de un período (8) — Etapa 6.
Pantallas: 25 reportes, 26 historial día por día, 27 exportar; 28–31 perfil, ajustes, ayuda, acerca de.

Este módulo **solo usa datos ya guardados**; no llama a OpenWeather.

## Componentes
- **CO-16** `HistorialRepositorio`: `condiciones(parcelaId, desde, hasta)` ordenando por id `yyyyMMdd`
  (sin índice extra); alertas por parcela y rango desde `AlertasRepositorio`.
- **CO-17** `ReportesServicio`: calcula el resumen y genera el PDF.

## HU-14 — Historial de alertas
Pestaña "Anteriores" del centro de alertas (plan 04) + filtro por parcela. Muestra si se atendió.

## HU-13 — Historial día por día (26)
Lista por día: fecha en palabras, mínima/máxima o temperatura registrada, lluvia del día, ícono de aviso si
hubo alerta ese día. Filtros **Todo / Con lluvia / Con aviso**. Paginación de 30 días.
Sin datos → "Todavía no hay días guardados de esta parcela".

## HU-16 — Reportes (25) y exportación (27)
- Período 7 o 30 días, por parcela.
- 4 indicadores: días con lluvia (`precipitacion ≥ 1 mm`), noche más fría (mín. temperatura registrada),
  lluvia acumulada (suma), avisos de peligro (alertas `critica` con `fechaEvento` en el período).
- Gráficas (fl_chart): temperatura por día y lluvia por día; cada una con una frase que la interpreta.
- Exportar: PDF con `pdf` + `printing` (encabezado AgroClima Jalapa, parcela, período, indicadores, tabla diaria,
  alertas, pie "Información de apoyo…"); guardar o compartir con `share_plus`.

## Perfil y soporte (Etapa 6)
- Perfil (28): nombre, correo, teléfono (editables salvo correo), accesos a parcelas, avisos, ajustes, ayuda, cerrar sesión.
- Ajustes (29): °C/°F, manzanas/hectáreas, tema oscuro, ahorro de datos → guardan en `usuarios/{uid}`
  y se aplican al instante. **Eliminar cuenta** al final, con confirmación doble y llamada a la función
  `eliminarCuenta` (MODELO_DATOS §6).
- Ayuda y glosario (30): preguntas frecuentes y palabras sencillas (helada, días sin lluvia, humedad…).
- Acerca de (31): de dónde salen los datos (OpenWeather, retícula, no es medición en la parcela — RT-02),
  que no es aviso oficial, versión, autor y universidad.

## Criterios de aceptación
- Normal: reporte de 7 días coincide con el historial de esos días.
- Alterno: período sin alertas → indicador en 0 y mensaje positivo.
- Error: sin señal → reporte con datos en caché e indicación de la fecha del último dato.
