# Plan 05 — Historial y reportes (MOD-05 · EP-05) + Perfil · Etapas 5 y 6

Historias: **HU-14** Historial de alertas (5) · **HU-13** Condiciones anteriores (8) — Etapa 5 ·
**HU-16** Resumen de un período (8) — Etapa 6.
Pantallas: 25 reportes, 26 historial día por día, 27 exportar; 28–31 perfil, ajustes, ayuda, acerca de.

Este módulo **solo usa datos ya guardados**; no llama a OpenWeather.

## Componentes
- **CO-16** `HistorialRepositorio`: `condiciones(parcelaId, desde, hasta)` ordenando por id `yyyyMMdd`
  (sin índice extra); alertas por parcela y rango desde `AlertasRepositorio`.
- **CO-17** `ReportesServicio`: calcula el resumen y arma los archivos (PDF, Excel, CSV) y la impresión (D-51).

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
- Guardar o enviar (27, D-51): el productor elige el período y el **formato**; todo se arma en el teléfono
  con los datos ya guardados (funciona sin señal, sin servidor y sin costo):
  - **Archivo PDF** — "Se abre en cualquier teléfono". Paquetes `pdf` + `printing`: encabezado AgroClima
    Jalapa, parcela, período, los 4 indicadores, tabla diaria, alertas y pie "Información de apoyo…".
  - **Hoja de Excel (.xlsx)** — "Para hacer cuentas en la computadora". Paquete `excel`: hojas *Resumen*
    (indicadores), *Días* (fecha, mínima, máxima, lluvia, aviso más alto) y *Avisos* (fecha, parcela,
    riesgo, nivel, valor esperado, lo que aguanta, si se atendió). Números como números, no como texto.
  - **Archivo CSV** — "Para otros programas". La tabla de *Días* (una fila por día), UTF-8 con BOM para que
    Excel lea las tildes, separador coma, punto decimal, fechas `AAAA-MM-DD` y encabezados en español sin
    tildes (`fecha,temperatura_minima,…`).
  - **Compartir**: el archivo elegido con `share_plus` (WhatsApp, correo, Drive o "Guardar en el teléfono").
  - **Imprimir**: el mismo PDF con `Printing.layoutPdf`, que abre el servicio de impresión de Android
    (impresora de la red o "Guardar como PDF"). Si el teléfono no tiene servicio de impresión, se avisa
    y se ofrece compartir.
  - Nombre del archivo: `agroclima_{parcela}_{desde}_{hasta}.{pdf|xlsx|csv}` (sin tildes ni espacios).

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
