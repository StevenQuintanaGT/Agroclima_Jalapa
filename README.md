# AgroClima Jalapa

Aplicación Android (Flutter) de monitoreo meteorológico y alertas de riesgo climático para productores
de los siete municipios de Jalapa. Proyecto de Graduación II, UMG. Guía de desarrollo: `CLAUDE.md`.

## Requisitos

- Flutter estable (Dart ≥ 3.13) y Android SDK con **NDK** (Android Studio → SDK Manager → SDK Tools →
  "NDK (Side by side)").
- Teléfono Android 8.0 o superior.
- Proyecto de Firebase en el plan gratuito **Spark** y clave de OpenWeather (plan Free). Costo cero: sin
  Blaze ni cuenta de facturación (DECISIONES D-37). Los mapas no necesitan clave.

## Configuración local (una sola vez)

Ninguno de estos archivos se sube al repositorio (RNF-04).

1. `android/local.properties`: copie `android/local.properties.example` y llene `sdk.dir` y `flutter.sdk`.
2. `env/dev.json`: copie `env/dev.example.json` y ponga su `OPENWEATHER_API_KEY`.
3. Firebase: `flutterfire configure` genera `android/app/google-services.json`. Sin ese archivo la app
   compila, pero no se conecta a Firebase.

## Comandos

```bash
flutter pub get
flutter run --dart-define-from-file=env/dev.json
flutter analyze && flutter test
flutter build apk --release --dart-define-from-file=env/prod.json
```

## Ciclo automático y reglas (`functions/`)

Requiere Node.js LTS y Firebase CLI (`npm install -g firebase-tools`, `firebase login`). Los emuladores
necesitan Java: sirve el de Android Studio (`JAVA_HOME=C:\Program Files\Android\Android Studio\jbr`).

```bash
cd functions && npm install
npm test                 # pruebas unitarias
npm run test:reglas      # pruebas de firestore.rules con el emulador
npm run test:emulador    # reglas + limpieza de parcelas borradas (emulador)
npm run emuladores       # auth y firestore en local (UI en http://localhost:4000)
```

Publicar reglas e índices: `firebase deploy --only firestore:rules,firestore:indexes` (plan Spark).

El ciclo de cada 3 horas (clima → alertas → avisos) lo ejecuta **GitHub Actions** con el código de
`functions/` (D-37). Necesita dos secretos en GitHub (Settings → Secrets and variables → Actions):
`OPENWEATHER_KEY` y `FIREBASE_SERVICE_ACCOUNT`.

### Probar la app contra los emuladores (sin tocar producción)

```bash
cd functions && npm run emuladores
```

En otra terminal:

```bash
flutter run --dart-define-from-file=env/dev.json --dart-define=USAR_EMULADORES=true
```

Cuentas de prueba: `functions/seed/cuentas_prueba_emulador.json`. Datos en http://localhost:4000.
