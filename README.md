# AgroClima Jalapa

**El clima de su parcela, antes de que pase.**

Aplicación Android de monitoreo meteorológico y alerta de riesgos climáticos para productores agrícolas de los
siete municipios del departamento de Jalapa: Jalapa, San Pedro Pinula, San Luis Jilotepeque, San Manuel
Chaparrón, San Carlos Alzatate, Monjas y Mataquescuintla.

Proyecto de Graduación II — Universidad Mariano Gálvez de Guatemala.
Tesis: *"Aplicación móvil de monitoreo meteorológico y alerta de riesgos climáticos para la producción agrícola
en Jalapa"*, de Marlon Steven Quintana Recinos.

[Descargar el APK (Android 8 o más)](https://github.com/StevenQuintanaGT/Agroclima_Jalapa/releases/latest)

> Las alertas son **información de apoyo**, no avisos oficiales. Para emergencias, siga lo que digan el
> INSIVUMEH y CONRED.

---

## Qué hace

| | |
|---|---|
| **Parcelas en el mapa** | El productor marca su parcela en un mapa satelital (o con la ubicación del teléfono), con su cultivo (maíz, frijol, café, hortalizas) y su etapa. Solo se aceptan puntos dentro de Jalapa. |
| **Clima de cada parcela** | Condiciones actuales y pronóstico hora por hora y de 5 días **de la parcela**, no del municipio. Funciona sin señal con el último dato guardado. |
| **Alertas automáticas** | Cada 3 horas se revisa el pronóstico. Si pasa lo que aguanta el cultivo en su etapa (helada, calor, lluvia fuerte, viento, sequía, humedad), llega un aviso al teléfono con una medida sugerida. |
| **Mapa del clima** | Capas de lluvia, nubes, temperatura y viento sobre el mapa de Jalapa. |
| **Historial y reportes** | Condiciones día por día y alertas anteriores. Resumen de un período que se exporta a **PDF, Excel o CSV** o se imprime. |
| **Perfil y ajustes** | °C o °F, manzanas o hectáreas, pantalla oscura, ahorro de datos, qué avisos recibir y horario de silencio, ayuda con glosario y eliminación de la cuenta. |

Pensada para productores de 25 a 60 años con teléfonos de gama media o baja y señal intermitente: letra grande,
botones de al menos 48 px, español llano y un semáforo de colores (verde, amarillo, rojo).

## Cómo funciona

```
┌─────────────── Teléfono (Flutter) ───────────────┐        ┌──────── GitHub Actions (cada 3 h) ────────┐
│ Pantallas + ViewModels (provider, MVVM)          │        │ functions/ (Node 22 + firebase-admin)      │
│        ↓                                         │        │  1. cuentas por eliminar                   │
│ Servicios del dominio                            │        │  2. limpieza de parcelas borradas          │
│        ↓                                         │        │  3. clima de cada celda (OpenWeather)      │
│ Repositorios (caché primero) ──┐                 │        │  4. motor de umbrales → alertas            │
└────────────────────────────────┼─────────────────┘        │  5. avisos por FCM                         │
                                 ↓                          └───────────────┬───────────────────────────┘
          Firebase Auth · Cloud Firestore (sin conexión) ←──────────────────┘
          Firebase Cloud Messaging · OpenWeather (plan Free) · teselas de Esri
```

- **Sin servidor propio y a costo cero**: Firebase en el plan gratuito **Spark** (sin Cloud Functions), el ciclo
  automático en una tarea programada de **GitHub Actions** y mapas de Esri sin clave (decisión D-37).
- **Tres capas** en la app que solo hablan con la inmediata. Los repositorios son contratos abstractos: se puede
  cambiar de proveedor de clima sin tocar las pantallas.
- **Caché primero**: se muestra lo guardado y solo se va a la red si el dato caducó; sin señal se avisa que el
  dato no está vigente.
- **Umbrales en Firestore**, no en el código: el catálogo por cultivo y etapa está en
  [`functions/seed/umbrales.json`](functions/seed/umbrales.json) y [`docs/UMBRALES.md`](docs/UMBRALES.md).
- Las parcelas se agrupan por celdas de ~5 km para no pasar la cuota gratuita de OpenWeather.

## Tecnologías

| Capa | Tecnología |
|---|---|
| App | Flutter / Dart, solo Android (minSdk 26 · Android 8.0) |
| Estado | `provider` (MVVM) · `go_router` |
| Cuenta | Firebase Authentication (correo y contraseña, Google) |
| Datos | Cloud Firestore con persistencia sin conexión |
| Ciclo automático | JavaScript (Node 22) + `firebase-admin`, en GitHub Actions |
| Avisos | Firebase Cloud Messaging + `flutter_local_notifications` |
| Clima | OpenWeather plan Free: Current Weather, 5 day / 3 hour Forecast, Weather Maps |
| Mapas | `flutter_map` + teselas de Esri · límites de geoBoundaries |
| Reportes | `fl_chart`, `pdf` / `printing`, `excel`, CSV |

## Estructura

```
lib/
├── config/         rutas, textos (todos los textos visibles), constantes y tema
├── modelos/        DTO del dominio (fromMap / toMap), nombres idénticos a Firestore
├── repositorios/   contratos + implementaciones (Firestore, OpenWeather, local)
├── servicios/      lógica del dominio (cuenta, parcelas, clima, alertas, reportes…)
├── pantallas/      una carpeta por módulo: pantalla + ViewModel
├── componentes/    widgets reutilizables (semáforo, tarjetas, estados vacíos…)
└── utilidades/     validadores, conversión de unidades, fechas, errores
test/               pruebas unitarias y de widget (mocktail)
functions/          ciclo automático, scripts y pruebas (jest + emulador)
.github/workflows/  ciclo del clima, sembrar umbrales, alertas de prueba
docs/               requisitos, modelo de datos, umbrales, diseño, decisiones y planes
```

Detalle carpeta por carpeta: [`ESTRUCTURA_PROYECTO.md`](ESTRUCTURA_PROYECTO.md).

## Documentación

| Documento | Contenido |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | Guía de desarrollo: pila, arquitectura, reglas de código y definición de listo |
| [`docs/REQUISITOS.md`](docs/REQUISITOS.md) | Historias de usuario, criterios, reglas de negocio y requisitos no funcionales |
| [`docs/MODELO_DATOS.md`](docs/MODELO_DATOS.md) | Colecciones de Firestore, campos, índices y reglas de seguridad |
| [`docs/UMBRALES.md`](docs/UMBRALES.md) | Catálogo de umbrales agrometeorológicos y algoritmo del motor de alertas |
| [`docs/DISENO_UI.md`](docs/DISENO_UI.md) | Paleta, tipografía, semáforo, pantallas y textos |
| [`docs/DECISIONES.md`](docs/DECISIONES.md) | Decisiones tomadas durante el desarrollo |
| [`docs/PLAN_DE_TRABAJO.md`](docs/PLAN_DE_TRABAJO.md) | Etapas, tareas y su estado |
| [`docs/plans/`](docs/plans/) | Plan de implementación de cada módulo |
| [`docs/diseno/`](docs/diseno/) | Mockups de las 35 pantallas |

---

## Desarrollo

### Requisitos

- Flutter estable (Dart ≥ 3.13) y Android SDK con **NDK** (Android Studio → SDK Manager → SDK Tools →
  "NDK (Side by side)").
- Node.js 22 y Firebase CLI (`npm install -g firebase-tools`, `firebase login`) para `functions/`. Los
  emuladores necesitan Java: sirve el de Android Studio (`JAVA_HOME=C:\Program Files\Android\Android Studio\jbr`).
- Proyecto de Firebase en el plan **Spark** y clave de OpenWeather (plan Free). Los mapas no necesitan clave.

### Configuración local (una sola vez)

Ninguno de estos archivos se sube al repositorio (RNF-04); `.gitignore` ya los excluye.

1. `android/local.properties`: copie `android/local.properties.example` y llene `sdk.dir` y `flutter.sdk`.
2. `env/dev.json`: copie `env/dev.example.json` y ponga su `OPENWEATHER_API_KEY`.
3. Firebase: `flutterfire configure` genera `android/app/google-services.json`. Sin ese archivo la app
   compila, pero no se conecta a Firebase.

### Comandos de la app

```bash
flutter pub get
flutter run --dart-define-from-file=env/dev.json
flutter analyze && flutter test
```

### Ciclo automático y reglas (`functions/`)

```bash
cd functions && npm install
npm test                 # pruebas unitarias
npm run test:reglas      # pruebas de firestore.rules con el emulador
npm run test:emulador    # reglas + ciclo completo con el emulador
npm run emuladores       # auth y firestore en local (UI en http://localhost:4000)
npm run simular:emulador -- <parcelaId> helada   # alertas simuladas en el emulador (helada, calor, lluvia, viento…)
```

Publicar reglas e índices: `firebase deploy --only firestore:rules,firestore:indexes` (funciona con Spark).

### Probar la app contra los emuladores (sin tocar producción)

```bash
cd functions && npm run emuladores
```

En otra terminal:

```bash
flutter run --dart-define-from-file=env/dev.json --dart-define=USAR_EMULADORES=true
```

Cuentas de prueba (solo existen en el emulador): `functions/seed/cuentas_prueba_emulador.json`.

### Tareas de GitHub Actions

Necesitan dos secretos del repositorio (Settings → Secrets and variables → Actions): `OPENWEATHER_KEY` y
`FIREBASE_SERVICE_ACCOUNT` (JSON de la cuenta de servicio de Firebase).

| Tarea | Cuándo | Qué hace |
|---|---|---|
| **Ciclo del clima** | Cada 3 h (y a mano) | Elimina cuentas pedidas, limpia parcelas borradas, trae el clima, evalúa umbrales, crea alertas y las avisa |
| **Sembrar umbrales** | A mano | Carga o actualiza el catálogo de umbrales en Firestore |
| **Alertas de prueba** | A mano | Manda 2 alertas marcadas como prueba (helada y lluvia fuerte) a la primera parcela de una cuenta, o las borra |

A mano: Actions → elegir la tarea → **Run workflow**.

### APK final firmado (RNF-09, RNF-25)

La app se entrega como APK (sin Play Store). Se firma con una llave propia que **no se sube a git** y que
hay que guardar en un lugar seguro: sin ella no se pueden instalar actualizaciones encima de la app.

1. Crear la llave una sola vez (pide la contraseña y los datos del dueño):

   ```bash
   keytool -genkey -v -keystore android/agroclima-entrega.jks -keyalg RSA -keysize 2048 -validity 10000 -alias agroclima -J-Duser.language=en
   ```

2. Copiar `android/key.properties.example` como `android/key.properties` y poner las contraseñas.
3. Copiar `env/dev.example.json` como `env/prod.json` con la clave de OpenWeather.
4. Compilar (solo ARM: todos los teléfonos Android reales; x86_64 es de emuladores y sumaba 23 MB):

   ```bash
   flutter build apk --release --target-platform android-arm,android-arm64 --obfuscate --split-debug-info=build/simbolos --dart-define-from-file=env/prod.json
   ```

   Sale en `build/app/outputs/flutter-apk/app-release.apk` (≈ 39 MB). Sin `key.properties` compila con la
   firma de prueba y Gradle lo avisa: sirve para probar, no para entregar.

5. Publicarlo como archivo de un **Release** de GitHub (nunca dentro del repositorio). Al cambiar de versión,
   subir `version` en `pubspec.yaml` y `versionApp` en `lib/config/constantes.dart`.

### Forma de trabajar

Una tarea a la vez en su rama (`feat/HU-xx-…`, `fix/…`, `docs/…`), commits en español con Conventional Commits
y PR a `main`. Antes de fusionar: `flutter analyze` sin errores y pruebas en verde. Detalle en
[`CLAUDE.md`](CLAUDE.md) §5–§7.

## Fuentes de datos y créditos

- Clima: [OpenWeather](https://openweathermap.org/) (plan gratuito). El dato es de un cuadro de unos 5 km, no
  una medición en el terreno.
- Mapas: teselas de Esri (World Imagery, World Boundaries and Places y Canvas).
- Límites municipales: [geoBoundaries](https://www.geoboundaries.org/) (CC BY 3.0 IGO).

Proyecto académico sin fines de lucro.
