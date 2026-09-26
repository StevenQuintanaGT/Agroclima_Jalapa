# CLAUDE.md — AgroClima Jalapa

Guía principal para Claude Code. Léela completa antes de tocar código. Todo lo que aquí se describe
viene de la tesis "Aplicación móvil de monitoreo meteorológico y alerta de riesgos climáticos para la
producción agrícola en Jalapa" (UMG, Proyecto de Graduación II, Marlon Steven Quintana Recinos).
**El código debe coincidir con la tesis.** Si algo de la tesis no se puede implementar tal cual,
no improvises: anótalo en `docs/DECISIONES.md` y pregunta.

## 1. Qué es el producto

Aplicación Flutter para Android dirigida a productores agrícolas de los **siete municipios del
departamento de Jalapa**: Jalapa, San Pedro Pinula, San Luis Jilotepeque, San Manuel Chaparrón,
San Carlos Alzatate, Monjas y Mataquescuintla.

El productor:
1. registra sus parcelas en un mapa (o con la ubicación del teléfono), con cultivo y etapa;
2. consulta el clima actual y el pronóstico de **cada parcela** (no del municipio);
3. recibe **alertas automáticas** cuando el pronóstico de los próximos 5 días supera los umbrales
   agrometeorológicos de su cultivo y etapa;
4. revisa el historial de condiciones y alertas, y genera resúmenes por período (PDF).

Usuarios: productores de 25 a 60 años, teléfonos Android de gama media/baja, señal intermitente,
poca costumbre con aplicaciones especializadas. **Esto manda sobre cualquier decisión de UI.**

## 2. Pila tecnológica (fija, no cambiar sin consultar)

| Capa | Tecnología |
|---|---|
| App | Flutter / Dart, solo Android, **minSdk 26 (Android 8.0)** |
| Estado y dependencias | `provider` (MVVM: pantalla + ViewModel `ChangeNotifier`) |
| Autenticación | Firebase Authentication (correo/contraseña y Google) |
| Base de datos | Cloud Firestore con persistencia sin conexión |
| Ciclo automático | Cloud Functions for Firebase (**JavaScript**, Node LTS), funciones programadas |
| Notificaciones | Firebase Cloud Messaging + `flutter_local_notifications` (canales) |
| Clima | OpenWeather, **plan gratuito**: Current Weather (2.5), 5 day / 3 hour Forecast (2.5), Weather Maps (teselas) |
| Mapas | `google_maps_flutter` (Google Maps para Android) |
| Ubicación | `geolocator` + `permission_handler` |
| Control de versiones | Git + GitHub |

Restricciones duras:
- **Costo cero.** Ningún servicio de pago. Única excepción aceptada: plan Blaze de Firebase
  (necesario para funciones programadas y secretos), manteniéndose dentro de la cuota gratuita.
- **No usar One Call 3.0** de OpenWeather (pide tarjeta). Solo los endpoints del plan Free.
- Cuota OpenWeather Free: 60 llamadas/min y 1 000 000/mes. El ciclo agrupa parcelas por celda (ver
  `docs/plans/03-monitoreo-meteorologico.md`).

## 3. Arquitectura (resumen; detalle en `ESTRUCTURA_PROYECTO.md`)

Cliente sin servidor propio. En el dispositivo, tres capas que **solo hablan con la inmediata**:

```
Presentación (pantallas + ViewModels, Provider)
      ↓
Lógica de negocio (servicios del dominio)
      ↓
Acceso a datos (repositorios: ÚNICOS que tocan Firestore, OpenWeather o almacenamiento local)
```

- Los repositorios se definen como **contratos abstractos** y se implementan aparte (RNF-20:
  cambiar de proveedor de clima sin tocar la presentación).
- Política **caché primero** en repositorios: se lee lo local, se evalúa vigencia, solo si caducó
  se va a la red; ante fallo se devuelve el último dato con aviso de "no vigente" (RNF-08).
- El **ciclo automático** (adquisición → evaluación de umbrales → alerta → envío FCM) vive en
  `functions/`, se ejecuta en la nube cada 3 horas y **no depende de que la app esté abierta**.
- Patrones: MVVM, Repositorio, Proveedor de dependencias, Observador (streams), Estrategia
  (reglas del motor), Fachada (cliente OpenWeather), Caché primero, DTO (modelos `fromMap/toMap`).

## 4. Dónde está cada cosa

| Documento | Contenido |
|---|---|
| `ESTRUCTURA_PROYECTO.md` | Árbol de carpetas y qué va en cada una |
| `docs/PLAN_DE_TRABAJO.md` | Orden en que se construye todo y estado de cada tarea |
| `docs/REQUISITOS.md` | Historias de usuario, criterios, reglas de negocio, RNF, validaciones |
| `docs/MODELO_DATOS.md` | Colecciones Firestore, campos exactos, índices y reglas de seguridad |
| `docs/UMBRALES.md` | Catálogo de umbrales y algoritmo del motor de alertas |
| `docs/DISENO_UI.md` | Paleta, tipografía, semáforo, pantallas, navegación y textos |
| `docs/DECISIONES.md` | Decisiones tomadas y asuntos abiertos |
| `docs/plans/00..05-*.md` | Plan de implementación por módulo (léelo antes de trabajar ese módulo) |
| `docs/diseno/` | Capturas de los mockups (35 pantallas) — referencia visual obligatoria |

## 5. Forma de trabajar

1. Antes de empezar una tarea, identifica su código (HT-xx / HU-xx) en `docs/PLAN_DE_TRABAJO.md` y lee el
   plan del módulo correspondiente.
2. Trabaja **una tarea a la vez**, en el orden del plan, en una rama `feat/HU-xx-descripcion-corta`
   (`fix/...`, `chore/...`, `docs/...` según el caso).
3. Commits en español, formato Conventional Commits: `feat(parcelas): validar límites de Jalapa (HU-03)`.
4. Al terminar, marca la tarea en `docs/PLAN_DE_TRABAJO.md` y verifica la **Definición de listo** (abajo).
5. Si una decisión no está en la documentación, **pregunta** antes de inventarla y luego regístrala en
   `docs/DECISIONES.md`.

## 6. Definición de listo (Tabla 47 de la tesis) — aplica a TODO

Un elemento está terminado solo si cumple las seis:
1. **Cumplimiento funcional**: todos sus criterios, **incluidos los de error** (sin señal, sin permiso,
   fuera de Jalapa, servicio caído).
2. **Integración**: fusionado a `main` sin romper lo anterior; `flutter analyze` sin errores y pruebas en verde.
3. **Dispositivo real**: probado en un teléfono físico Android ≥ 8.0 de gama media, no solo emulador.
4. **Conectividad**: probado con conexión estable, intermitente y sin conexión.
5. **Lenguaje**: textos en español llano, sin términos técnicos (ver `docs/DISENO_UI.md` §6).
6. **Consumo**: no agrega llamadas que pongan en riesgo la cuota gratuita.

## 7. Reglas de código

- Dart: `flutter_lints` activo; `dart format` antes de cada commit; sin `print` (usar `debugPrint` o logger).
- **Nombres del dominio en español y sin tildes** (`Parcela`, `Alerta`, `celdaClima`, `nivelMinimo`),
  idénticos a los campos de Firestore de `docs/MODELO_DATOS.md`. Los valores de enumeraciones que se
  guardan en la base también son exactamente los de ese documento.
- Archivos en `snake_case`; una clase pública principal por archivo.
- Los ViewModels no importan `package:flutter/material.dart` salvo `ChangeNotifier`
  (`foundation.dart`); no conocen widgets.
- Las pantallas no llaman repositorios ni Firebase directamente: solo a su ViewModel.
- **Todos los textos visibles** van en `lib/config/textos.dart` (no strings sueltos en widgets), para
  poder revisarlos con productores (RNF-13).
- Valores de clima siempre se **guardan en unidades métricas** (°C, mm, km/h, %) y se convierten solo
  al mostrar (°F, hectáreas) según preferencias del usuario.
- Fechas: se guardan en UTC (`Timestamp`); los ids diarios `yyyyMMdd` se calculan en hora de
  Guatemala (`America/Guatemala`, UTC-6).
- Pruebas: unitarias para servicios, validadores, conversiones y reglas del motor; de widget para
  pantallas clave. Mocks con `mocktail`. En `functions/`, pruebas con el emulador de Firebase.

## 8. Secretos y configuración (RNF-04)

Nunca subir al repositorio:
- `android/app/google-services.json`, `lib/firebase_options.dart`
- `env/*.json` (claves para `--dart-define-from-file`), `android/local.properties`, `android/key.properties`, `*.jks`
- `functions/.env*`, `functions/.secret.local`

Claves:
- **OpenWeather (app)**: `OPENWEATHER_API_KEY` en `env/dev.json`, se lee con `String.fromEnvironment`.
- **OpenWeather (funciones)**: secreto `OPENWEATHER_KEY` con `defineSecret` (Secret Manager).
- **Google Maps**: `MAPS_API_KEY` en `android/local.properties` → `manifestPlaceholders`; en Google
  Cloud se restringe al paquete `gt.umg.agroclima_jalapa` y a la huella SHA-1.
- Se incluyen plantillas versionadas: `env/dev.example.json`, `android/local.properties.example`.

## 9. Comandos

```bash
flutter pub get
flutter run --dart-define-from-file=env/dev.json
flutter analyze && flutter test
flutter build apk --release --dart-define-from-file=env/prod.json   # entrega por APK (RNF-25), ≤ 50 MB (RNF-09)

cd functions && npm install && npm test
firebase emulators:start --only auth,firestore,functions
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions
node functions/scripts/sembrar-umbrales.js      # carga el catálogo de umbrales
```

## 10. Cosas que NO se hacen

- No agregar funciones fuera de la pila del producto (IoT, sensores, SMS, Play Store, web, iOS).
- No escribir desde la app en `pronosticos`, `umbrales` ni crear `alertas` (solo funciones de la nube).
- No poner umbrales fijos en el código de la app: se leen de Firestore (RNF-19).
- No mostrar códigos de error ni mensajes en inglés al productor.
- No presentar las alertas como avisos oficiales: siempre "información de apoyo" (RN-07).
- No pedir permisos al abrir la app: ubicación y notificaciones se piden en su pantalla propia (RNF-05).
