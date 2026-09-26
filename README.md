# AgroClima Jalapa

Aplicación Android (Flutter) de monitoreo meteorológico y alertas de riesgo climático para productores
de los siete municipios de Jalapa. Proyecto de Graduación II, UMG. Guía de desarrollo: `CLAUDE.md`.

## Requisitos

- Flutter estable (Dart ≥ 3.13) y Android SDK con **NDK** (Android Studio → SDK Manager → SDK Tools →
  "NDK (Side by side)").
- Teléfono Android 8.0 o superior.
- Proyecto de Firebase y claves de OpenWeather (plan Free) y Google Maps (ver `docs/plans/00-configuracion-inicial.md`).

## Configuración local (una sola vez)

Ninguno de estos archivos se sube al repositorio (RNF-04).

1. `android/local.properties`: copie `android/local.properties.example` y llene `sdk.dir`, `flutter.sdk`
   y `MAPS_API_KEY`.
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

Funciones de la nube (`functions/`): ver `CLAUDE.md` §9.
