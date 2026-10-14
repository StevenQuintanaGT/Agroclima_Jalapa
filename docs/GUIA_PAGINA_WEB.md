# Guía para otra sesión: página web de presentación de AgroClima Jalapa

> Léela completa antes de empezar. También lee `CLAUDE.md` (secciones 1, 2, 8 y 10), `docs/DISENO_UI.md`
> (paleta, tipografía, textos) y `docs/DECISIONES.md` (D-37, D-51, D-55, D-56).

## 1. Qué hay que construir

Una **página web de presentación** del producto, de una sola página, para dos públicos:

1. **Productores de Jalapa** (25 a 60 años, teléfonos Android de gama media o baja, señal intermitente): que
   entiendan qué hace la app en 10 segundos, la **descarguen (APK)** y sepan instalarla.
2. **Jurado y docentes de la UMG**: que vean el proyecto académico, lean la **tesis** y revisen el
   **repositorio**.

**No es una versión web de la app.** `CLAUDE.md` §10 prohíbe "web" como plataforma del producto: la app sigue
siendo solo Android. La página es material de presentación. **Antes de programar**, registra esto como
**D-57** en `docs/DECISIONES.md` ("Página de presentación en GitHub Pages; no es una versión web de la
app") y confírmalo con Steven.

## 2. Restricciones (no negociables)

- **Costo cero** (D-37): **GitHub Pages** para la página y **GitHub Releases** para el APK y la tesis. Nada de
  Firebase Hosting (el plan Spark da 360 MB/día de transferencia: el APK pesa 38.9 MB), Vercel, dominios
  pagados ni servicios con tarjeta.
- **Sin secretos**: no subir el APK, `google-services.json`, `env/*.json`, `key.properties` ni la llave `.jks`
  al repositorio. El APK va **solo** como archivo de un Release.
- **Liviana**: HTML + CSS + lo mínimo de JS, **sin frameworks ni paso de compilación**. La página sin
  imágenes debe pesar menos de 100 KB y con imágenes menos de 1 MB (WebP comprimidas, `loading="lazy"`).
  Fuentes: Roboto del sistema (`font-family: Roboto, system-ui, sans-serif`); no cargar Google Fonts.
- **Sin rastreo**: sin analytics, cookies ni banners de cookies.
- **Lenguaje** (`docs/DISENO_UI.md` §6): español llano, trato de **usted**, sin términos técnicos para la
  parte de productores ("archivo de instalación", no "APK"; aunque el botón puede decir "Descargar la app
  (APK)").
- **Las alertas son información de apoyo**, no avisos oficiales (RN-07): decirlo en la página.
- **Móvil primero**: diseñar para 360 px de ancho; tocables de al menos 48 px; contraste AA.

## 3. Dónde va cada cosa

```
sitio/                          ← la página (se publica tal cual)
├── index.html
├── estilos.css
├── img/                        ← logo.svg, capturas .webp, icono para el favicon
└── (sin node_modules ni build)
.github/workflows/pagina.yml    ← publica sitio/ en GitHub Pages
```

- Rama: `feat/pagina-presentacion`. Commits en español, Conventional Commits, con la línea
  `Co-Authored-By` que indique la sesión. PR a `main`.
- Workflow `pagina.yml`: se dispara con `push` a `main` cuando cambia `sitio/**` y con `workflow_dispatch`.
  Usa `actions/configure-pages`, `actions/upload-pages-artifact` (ruta `sitio`) y `actions/deploy-pages`, con
  permisos `pages: write` e `id-token: write`. Sin dependencias de Node.
- Dirección final: **https://stevenquintanagt.github.io/Agroclima_Jalapa/**.

## 4. Contenido (en este orden)

Saca los textos de la app para que coincidan (`lib/config/textos.dart`): lema, preguntas, términos y
glosario.

1. **Encabezado**: logo, "AgroClima Jalapa" y el lema **"El clima de su parcela, antes de que pase"**.
   Botón principal grande **"Descargar la app"** con "Android 8 o más · 38.9 MB · versión 1.0.0" debajo.
2. **Qué hace** (4 bloques con ícono, de `CLAUDE.md` §1): registra sus parcelas en el mapa; clima y
   pronóstico de 5 días **de cada parcela**; **avisos automáticos** cuando el pronóstico pasa lo que aguanta
   su cultivo (maíz, frijol, café, hortalizas); historial y reportes en PDF, Excel o CSV.
3. **Para los 7 municipios**: Jalapa, San Pedro Pinula, San Luis Jilotepeque, San Manuel Chaparrón, San
   Carlos Alzatate, Monjas y Mataquescuintla.
4. **Capturas**: 4 a 6 imágenes. Lo ideal son **capturas reales del teléfono de Steven** (pídeselas). Si no
   hay, usar los mockups de `docs/diseno/pantallas/` (17 panel, 19 pronóstico, 20 mapa, 22 detalle de alerta,
   25 reportes) e indicar "Diseño de la app". Convertir a WebP de 400 px de ancho.
5. **Cómo instalarla** (pasos numerados y con palabras sencillas; son los que ya se probaron con Steven):
   1. Toque "Descargar la app" y espere a que baje el archivo.
   2. Ábralo desde **Archivos → Descargas**.
   3. Si el teléfono pide permiso para "instalar apps desconocidas", actívelo y vuelva atrás.
   4. Toque **Instalar**. Si Play Protect dice que no conoce la app, toque **Más detalles → Instalar de todas
      formas** (pasa porque no viene de la Play Store).
   5. Abra AgroClima, cree su cuenta y registre su parcela.
6. **Preguntas comunes**: las de `Textos.preguntas` (¿Por qué no me llegan avisos?, ¿Funciona sin señal?,
   ¿Los avisos son oficiales?, …) con `<details>/<summary>` (sin JS).
7. **De dónde salen los datos**: OpenWeather (por un cuadro de unos 5 km, no es medición en su terreno),
   mapas de Esri, límites de geoBoundaries. **"Es información de apoyo; para emergencias, siga lo que digan
   el INSIVUMEH y CONRED."**
8. **Privacidad y términos**: los puntos de `Textos.terminos` (qué se guarda, que no se vende, cómo eliminar
   la cuenta desde Ajustes).
9. **El proyecto** (para el jurado): "Aplicación móvil de monitoreo meteorológico y alerta de riesgos
   climáticos para la producción agrícola en Jalapa", Proyecto de Graduación II, Universidad Mariano Gálvez
   de Guatemala, autor **Marlon Steven Quintana Recinos**. Enlaces a:
   - **Tesis (PDF)**, como archivo del Release (ver §5).
   - **Repositorio**: https://github.com/StevenQuintanaGT/Agroclima_Jalapa
   - Tecnologías en una línea: Flutter, Firebase (plan gratuito), OpenWeather, GitHub Actions, flutter_map +
     Esri.
10. **Pie**: versión, año, "Proyecto académico sin fines de lucro" y los créditos de datos.

## 5. Descargas: APK y tesis en GitHub Releases

El APK firmado **solo existe en la PC de Steven** (`C:\Users\msqui\Documents\UMG\PG\APK\`) porque la llave de
firma no sale de esa máquina (D-56). Una sesión en la nube **no puede** compilar el APK firmado: lo sube
Steven, o una sesión local en su PC.

- Nombre fijo del archivo dentro del Release: **`AgroClima-Jalapa.apk`**. Así el botón usa un enlace que no
  cambia con cada versión:
  `https://github.com/StevenQuintanaGT/Agroclima_Jalapa/releases/latest/download/AgroClima-Jalapa.apk`
- Comando (en la PC de Steven, desde la carpeta del repositorio):

  ```bash
  cp "C:/Users/msqui/Documents/UMG/PG/APK/AgroClima-Jalapa-1.0.0.apk" AgroClima-Jalapa.apk
  gh release create v1.0.0 AgroClima-Jalapa.apk --title "AgroClima Jalapa 1.0.0" --notes "Primera versión para Android 8 o más."
  rm AgroClima-Jalapa.apk
  ```

- **Tesis**: el documento está en `C:\Users\msqui\Documents\UMG\PG\Entrega\` (`PGII Entrega 3 - Marlon
  Quintana.docx`; la Entrega 2 está en PDF). **Antes de publicarla, preguntar a Steven** si la versión final
  puede ser pública (permiso de la universidad) y cuál versión subir. Si dice que sí: exportarla a PDF y
  agregarla al mismo Release como **`Tesis-AgroClima-Jalapa.pdf`**
  (`gh release upload v1.0.0 Tesis-AgroClima-Jalapa.pdf`). Si no, la página muestra solo el título, el
  resumen y "Disponible en la Universidad Mariano Gálvez".
- **No** guardar el APK ni la tesis dentro de `sitio/` ni en git.
- En la página, debajo del botón, poner la huella SHA-256 del certificado de firma para quien quiera
  verificar: `29:59:45:5F:15:D8:3C:FE:72:32:E3:58:F9:26:35:1C:0D:E7:5E:D2:90:23:6A:A2:18:F5:C6:FC:7D:46:82:5B`
  (es pública; no es la contraseña).

## 6. Diseño visual (igual que la app)

Tokens de `lib/config/tema/colores.dart` (como variables CSS en `:root`):

| Token | Color | Uso |
|---|---|---|
| primarioOscuro | `#1B5E20` | encabezado, logo |
| primario | `#2E7D32` | botón principal, enlaces |
| contenedorClaro | `#E8F5E9` | fondos de tarjetas destacadas |
| fondo | `#F7F6F2` | fondo de la página |
| superficie | `#FFFFFF` | tarjetas |
| texto / textoSecundario | `#1A1C19` / `#3D4139` | texto |
| acentoCielo | `#0277BD` | lluvia, agua |
| precaución / peligro | `#B26A00` / `#B3261E` | ejemplo del semáforo de avisos |

- Tema oscuro con `prefers-color-scheme` usando `fondoOscuro #10130F`, `superficieOscura #1E231C`,
  `primarioTemaOscuro #A5D6A7`.
- **Logo**: la nube con lluvia del ícono de la app. Convertir a SVG los trazos de
  `android/app/src/main/res/drawable/ic_launcher_frente.xml` (nube + 3 líneas de lluvia, blanco) sobre un
  cuadro redondeado `#1B5E20` (radio 30 %). Úsalo también como favicon.
- Tarjetas con radio de 16 px, botones de 56 a 60 px de alto con radio de 14 px, cuerpo de 18 px.
- Mira `docs/diseno/pantallas/31-acerca-de.png` y `01-splash.png` como referencia de tono.

## 7. Cómo verificar antes del PR

- Abrir `sitio/index.html` en el navegador a **360 px** y a 1280 px; sin desbordes horizontales.
- Todos los enlaces funcionan: el botón de descarga (cuando ya exista el Release), el repositorio y la tesis.
- Lighthouse en móvil: Rendimiento, Accesibilidad y Buenas prácticas en 90 o más.
- Validar el HTML (sin errores) y que las imágenes tengan `alt` en español.
- Peso total menor de 1 MB.
- Después de fusionar: revisar que el workflow publicó y que la dirección de §3 abre la página.

## 8. Lo que tiene que hacer Steven (la sesión se lo pide al final)

1. **Activar Pages**: GitHub → Settings → Pages → *Build and deployment* → Source: **GitHub Actions**.
2. **Crear el Release v1.0.0** con el APK (comando de §5), en su PC.
3. **Decidir sobre la tesis**: si se publica, qué versión, y exportarla a PDF.
4. **Mandar 4 a 6 capturas reales** del teléfono (panel, pronóstico, mapa, un aviso, reportes).
5. Opcional: en la página del repositorio, *About* → poner la dirección de la página como *Website*.

## 9. Cuando salga una versión nueva de la app

Subir `versionApp` en `lib/config/constantes.dart` y `version` en `pubspec.yaml` (una prueba vigila que sean
iguales), compilar el APK firmado en la PC de Steven (README, "APK final firmado"), crear un Release nuevo
(`v1.0.1`, …) con el mismo nombre de archivo **`AgroClima-Jalapa.apk`** y actualizar en `sitio/index.html` la
versión y el tamaño. El enlace `releases/latest/download/...` apunta solo a la versión nueva.
