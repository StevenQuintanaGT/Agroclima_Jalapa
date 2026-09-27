# Diseño — AgroClima Jalapa

Importado de Claude Design (proyecto `eeeebf0b-4372-477f-942b-b7b166c2b4ee`) el 2026-09-26.

| Archivo | Contenido |
|---|---|
| `App Agrometeorologica.dc.html` | Lienzo completo: sistema de diseño + 28 pantallas (35 frames) + 5 flujos. Cada frame lleva debajo su nota de diseño. Se abre en el navegador (necesita `support.js` del proyecto de diseño para verse igual; el contenido se lee sin él). |
| `pantallas/00-sistema-*.png` | Paleta, tipografía, componentes e iconografía. |
| `pantallas/01..35-*.png` | Captura de cada pantalla, numeradas igual que la tabla de `docs/DISENO_UI.md` §7. |

## Cómo usarlo

- **Visual (colores, tamaños, radios, espaciado, textos):** manda el diseño. Medidas en px = dp, texto en sp.
- **Comportamiento, datos y arquitectura:** manda la tesis y `docs/`. El handoff original del diseño
  propone One Call, WorkManager, Room, 7 días de pronóstico, índice UV y umbrales editables por el
  usuario; nada de eso aplica tal cual. Ver `docs/DECISIONES.md` (D-01, D-02, D-04, D-14, D-18 a D-21).
- Ilustraciones (recuadros punteados "ILUSTRACIÓN") y logotipo son **provisionales**; los mapas
  (rayas "MAPA GOOGLE MAPS") se implementan con `google_maps_flutter` + teselas OpenWeather.
- Iconos: Material Symbols Outlined, peso 400. **Todo icono lleva su palabra.**
- Severidad: siempre color + icono + palabra en mayúscula + franja lateral.
