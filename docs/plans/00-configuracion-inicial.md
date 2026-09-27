# Plan 00 — Configuración inicial (HT-01, HT-02) · Etapa 1

## Objetivo
Proyecto Flutter compilando en Android 8.0+, conectado a Firebase, con tema, navegación base,
reglas de seguridad desplegadas y secretos fuera del repositorio.

## Pasos que hace Steven (fuera del código)
1. `flutter create --org gt.umg --project-name agroclima_jalapa --platforms android .` en la carpeta App.
2. Crear proyecto en Firebase Console (`agroclima-jalapa`), activar: Authentication (correo/contraseña y
   Google), Firestore (región `us-central1` o la más cercana disponible), Cloud Messaging. Pasar a
   **Blaze** con alerta de presupuesto de US$1 (necesario para funciones programadas y secretos).
3. `dart pub global activate flutterfire_cli` y `flutterfire configure` (genera `firebase_options.dart`
   y `google-services.json`, ambos ignorados por git).
4. Registrar la huella SHA-1 de depuración en Firebase (para Google Sign-In) y en la clave de Maps.
5. Crear clave de OpenWeather (plan Free) y clave de Google Maps SDK for Android restringida al paquete.
6. `firebase init` con Firestore, Functions (JavaScript), Emulators.
7. Crear el repositorio en GitHub y hacer el primer commit.

## HT-01 — lo que hace Claude Code
- [x] `pubspec.yaml`: agregar dependencias de `ESTRUCTURA_PROYECTO.md` con `flutter pub add`.
- [x] `android/app/build.gradle(.kts)`: `minSdk = 26`, `applicationId = "gt.umg.agroclima_jalapa"`,
      lectura de `MAPS_API_KEY` desde `local.properties` → `manifestPlaceholders`.
- [x] `AndroidManifest.xml`: permisos solo `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`,
      `POST_NOTIFICATIONS` (RNF-05); meta-data de la clave de Maps; canal de notificación por defecto.
- [x] `.gitignore` con todo lo de `CLAUDE.md` §8; plantillas `env/dev.example.json` y `android/local.properties.example`.
- [x] Estructura de carpetas vacía de `lib/` según `ESTRUCTURA_PROYECTO.md`.
- [ ] `config/tema/`: colores (Tabla 71 + semáforo con D-04), tipografía (Tabla 73), `ThemeData` claro y
      oscuro con Material 3, botones de 56 dp, radios 8/16.
- [ ] `config/textos.dart` con los textos de las pantallas de acceso.
- [ ] `config/rutas.dart`: go_router con `StatefulShellRoute` para los 5 destinos y guarda de sesión
      (sin sesión → `/bienvenida`; con sesión → `/inicio`).
- [ ] Componentes transversales base: `ChipSemaforo`, `BotonPrincipal`, `EsqueletoCarga`, `EstadoVacio`,
      `EstadoError`, `AvisoNoVigente`, `AvisoApoyo`.
- [x] `utilidades/unidades.dart` y `fechas.dart` con pruebas unitarias
      (1 mz = 0.6987 ha; °F = °C × 9/5 + 32; km/h = m/s × 3.6; id `yyyyMMdd` en UTC-6).
- [~] `main.dart` (falta `MultiProvider`, llega con los primeros repositorios): `Firebase.initializeApp`, persistencia de Firestore, `MultiProvider` con repositorios y servicios.
- [x] `README.md` con pasos para correr el proyecto.

## HT-02 — lo que hace Claude Code
- [ ] `firestore.rules` exactamente como `MODELO_DATOS.md` §5.
- [ ] `firestore.indexes.json` con los 2 índices de §4.
- [ ] `functions/` inicializado en JavaScript, con `jest`, `config.js` y un `index.js` vacío exportable.
- [ ] Pruebas de reglas con el emulador (`@firebase/rules-unit-testing`) para los 5 casos de §5.
- [ ] `functions/scripts/sembrar-umbrales.js` + `seed/umbrales.json` (se ejecuta en HT-03, se deja listo).

## Criterios de terminado
- `flutter run` abre la app en teléfono físico con Android ≥ 8; `flutter analyze` limpio.
- `firebase emulators:start` levanta auth, firestore y functions; pruebas de reglas en verde.
- `git status` no muestra ningún archivo de claves.
