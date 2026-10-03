# Plan de trabajo

Orden en que se construye la aplicación. **No se trabaja por sprints ni con fechas**: se avanza etapa por
etapa y dentro de cada una tarea por tarea. El orden respeta las dependencias técnicas de la tesis
(Tabla 42): sin cuenta no hay parcelas, sin parcelas no hay clima, sin clima no hay alertas y sin alertas
no hay historial.

Estados: `[ ]` pendiente · `[~]` en curso · `[x]` terminada (cumple la Definición de listo de `CLAUDE.md` §6).
Al terminar cada etapa, generar un **APK de prueba** e instalarlo en un teléfono real.

---

## Etapa 1 — Base del proyecto y acceso · `plans/00`, `plans/01`
- [x] **HT-01** Configuración inicial Flutter (dependencias, Android minSdk 26, secretos, estructura)
- [x] Tema visual, componentes transversales base y navegación con barra inferior
- [x] **HT-02** Proyecto Firebase, reglas de seguridad e índices (con pruebas de reglas)
- [x] **HU-01** Registro de usuario
- [~] **HU-02** Sesión persistente (+ recuperación de contraseña y pantallas de permisos)

Resultado: splash, onboarding, registro, inicio de sesión, permisos y shell con los 5 destinos.

## Etapa 2 — Parcelas · `plans/02`
- [x] Archivo de límites de Jalapa y validador geográfico (D-11)
- [x] **HU-03** Ubicación de la parcela en el mapa
- [x] **HU-04** Registro por ubicación del teléfono
- [x] **HU-05** Nombre, cultivo y etapa (registro en 4 pasos)
- [x] **HU-06** Listado, edición y eliminación (+ función de borrado en cascada)

## Etapa 3 — Clima de la parcela · `plans/03`
- [x] Cliente OpenWeather (app y funciones)
- [x] Función `adquirirClima` (guarda `pronosticos` y `condiciones` por celda)
- [ ] **HU-07** Condiciones actuales (panel principal)
- [ ] **HU-15** Consulta sin conexión (caché primero)
- [ ] **HU-08** Pronóstico de los próximos días (+ detalle de pronóstico)

## Etapa 4 — Motor de alertas · `plans/04`
- [ ] **HT-03** Catálogo de umbrales (semilla en Firestore)
- [ ] **HT-04** Evaluación periódica (reglas por tipo de riesgo, con pruebas)
- [ ] **HU-10** Notificación por riesgo climático (duplicados, preferencias, silencio, FCM)
- [ ] **HU-11** Centro de alertas y detalle
- [ ] **HU-12** Preferencias por tipo de alerta ("Mis avisos")

## Etapa 5 — Mapa e historial · `plans/03` §7, `plans/05`
- [ ] **HU-09** Capas del clima en el mapa
- [ ] **HU-14** Historial de alertas
- [ ] **HU-13** Registro de condiciones anteriores (historial día por día)

## Etapa 6 — Reportes, perfil y cierre · `plans/05`
- [ ] **HU-16** Resumen de un período + exportar PDF
- [ ] Perfil, ajustes, ayuda y glosario, acerca de, eliminar cuenta
- [ ] Ajustes que salgan de las pruebas con productores
- [ ] APK final firmado (≤ 50 MB)

---

## Dependencias (Tabla 42)

```
HT-01 → HT-02 → HU-01/HU-02 → HU-03/HU-04 → HU-05/HU-06
                                   └→ HU-07/HU-08 → HU-15
                                   └→ HU-09
HU-05 → HT-03 ─┐
HU-07 ─────────┴→ HT-04 → HU-10 → HU-11/HU-12, HU-14
HU-07 → HU-13 ;  HU-13 + HU-14 → HU-16
```

Se puede adelantar una tarea de una etapa posterior solo si sus dependencias ya están terminadas.

## Notas de avance

- **Pendiente general:** prueba en teléfono físico Android ≥ 8.0 de gama media de todas las tareas (D-30).
- HU-01: el foco del teclado pasaba al botón "Ver" en vez del siguiente campo; corregido y con prueba.
- Sin señal, Firebase Auth puede responder `unknown` en vez de `network-request-failed`; se reconoce por el mensaje.
- HU-02: todo verificado en el emulador salvo **entrar con Google** (programado y con pruebas, pero falta activar el proveedor Google y volver a descargar `google-services.json`).
- `MarcoPunteado` dibujaba el borde debajo del fondo y no se veía; corregido (afectaba ilustraciones, "Datos del…" y error de servicio).
- HU-03: probado en el emulador con el mapa satelital de Esri (tocar, arrastrar el pin, búsqueda, "Usar mi ubicación", guardado en Firestore).
- **D-37: sin plan Blaze.** Mapas con flutter_map + Esri; el ciclo automático correrá en GitHub Actions. Actualizar la tesis.
- HU-06: probado en el emulador (lista, deslizar, editar cultivo, detalle, borrar con y sin señal, sincronización al volver la señal). La limpieza en cascada (`functions/src/limpieza.js`) ya está programada y probada con el emulador; se ejecutará sola cuando se cree la tarea de GitHub Actions (Etapa 3). Ver D-38.
- Cliente OpenWeather (D-39): probado con respuestas de ejemplo en Dart y en JavaScript; **falta probarlo con una clave real** (no hay `OPENWEATHER_API_KEY` en `env/dev.json`).
- `adquirirClima` y la tarea de GitHub Actions (D-40, D-41): probados con el emulador y un clima falso. Para que corra en la nube faltan los secretos `OPENWEATHER_KEY` y `FIREBASE_SERVICE_ACCOUNT` en GitHub.

(Espacio libre para anotar problemas encontrados — cuota, conectividad, comportamiento de algún teléfono —
y lo que se decidió.)
