# Decisiones y asuntos abiertos

Registro de decisiones de implementación que la tesis no fija al detalle, o donde el mockup y la tesis
no coinciden. **Regla:** el código sigue la tesis (Cap. IV y V); el mockup manda solo en lo visual.
Estado: ✅ decidida · ⏳ por confirmar con Steven.

| ID | Tema | Decisión | Estado |
|---|---|---|---|
| D-01 | Cultivos | El modelo usa los 4 de la tesis: `maiz`, `frijol`, `cafe`, `hortalizas`. El mockup muestra "Maíz y frijol" juntos y "Frutales"; en la app van **Maíz** y **Frijol** por separado (tienen umbrales distintos) y **no** se incluye Frutales (sin umbrales en la tesis). El paso 2 del registro se ajusta a 4 botones. | ⏳ |
| D-02 | Etapas | Valores de la tesis: `siembra`, `desarrolloVegetativo`, `floracion`, `llenado`, `cosecha`. Etiquetas llanas: Siembra, Creciendo, Floreando, Llenando el grano o la vaina, Cosecha. El mockup dice "Crecimiento" y "Maduración": se mapean a `desarrolloVegetativo` y `llenado`. | ⏳ |
| D-03 | Acceso | Correo + contraseña (mín. 8) y cuenta de Google (§5.6.1). El teléfono +502 es dato de contacto, no método de acceso: el ingreso por SMS tiene costo y la tesis no lo diseña. | ✅ |
| D-04 | Contraste PRECAUCIÓN | #B26A00 sobre #FFF3D6 = 3.84:1 (incumple WCAG AA). Se usa **#9A5B00** (4.92:1) para texto e ícono; #B26A00 queda solo como color decorativo si hace falta. Actualizar la Tabla 72 de la tesis. | ⏳ |
| D-05 | Campos extra en alertas | Se agregan `parcelaNombre`, `cultivo`, `diasConsecutivos` y `notificada` para mostrar la alerta sin leer la parcela y para saber si se envió. No cambian el diseño; se pueden mencionar en la tesis como campos desnormalizados. | ⏳ |
| D-06 | Periodicidad del ciclo | Cada **3 horas** (coincide con la resolución del pronóstico de 5 días/3 h del plan gratuito). Zona horaria `America/Guatemala`. | ✅ |
| D-07 | Celda climática | Coordenadas redondeadas a **0.05°** (≈ 5.5 km): `celdaClima = "${round(lat/0.05)*0.05}_${round(lon/0.05)*0.05}"` con 2 decimales, ej. `14.65_-89.95`. La consulta usa el centro de la celda. Constante configurable. | ✅ |
| D-08 | Vigencia del dato | Condiciones actuales: 60 min (180 min con ahorro de datos). Pronóstico: 3 h. Pasado ese tiempo el dato se muestra con aviso "no vigente" si no se puede actualizar (RR-03). | ✅ |
| D-09 | Endpoints OpenWeather | Solo plan Free: `/data/2.5/weather` (actual), `/data/2.5/forecast` (5 días cada 3 h), teselas `tile.openweathermap.org/map/{capa}/{z}/{x}/{y}.png` (`precipitation_new`, `clouds_new`, `temp_new`, `wind_new`). `units=metric`, `lang=es`. No One Call 3.0. | ✅ |
| D-10 | Pronóstico diario desde 3 h | Se agrupan las 8 franjas de cada día en hora de Guatemala: `temperaturaMinima` = mín de `main.temp_min`; `temperaturaMaxima` = máx de `main.temp_max`; `precipitacionHora` = máx de `rain.3h / 3`; `acumuladoDia` = suma de `rain.3h`; `velocidadViento` = máx de `wind.speed × 3.6`; `humedadRelativa` = promedio de `main.humidity`. | ✅ |
| D-11 | Límites de Jalapa | Validación con polígonos de los 7 municipios en `assets/geo/jalapa_municipios.geojson` (fuente sugerida: geoBoundaries, Guatemala ADM2, licencia abierta; filtrar a los 7 y simplificar). Punto en polígono propio (ray casting), sin servicios externos. | ⏳ fuente |
| D-12 | Pronóstico por horas en el panel | Se pide al abrir el panel con la clave de la app y se guarda solo en caché local (`shared_preferences`), porque la app no puede escribir `pronosticos`. Los próximos días salen de `pronosticos` (Firestore). | ✅ |
| D-13 | Duplicados | Una alerta por parcela + tipo de riesgo + día del evento; si el nivel sube se crea otra (ver `UMBRALES.md` §5). | ✅ |
| D-14 | Temperatura 4 °C del mockup | El mockup de detalle de alerta dice "el café aguanta 4 °C"; no tiene fuente. La app muestra el valor del umbral real (Tabla 31, p. ej. 15 °C). | ✅ |
| D-15 | "Helada" en un objetivo específico | Se mantiene el umbral general de helada ≤ 0 °C (Bardales Espinoza et al., 2019), que aplica sobre todo a zonas altas (> 1 700 msnm) como Mataquescuintla. | ✅ |
| D-16 | Package name | `gt.umg.agroclima_jalapa`. | ⏳ |
| D-17 | Forma de trabajo | En la práctica **no se usan sprints**: se sigue el orden de `PLAN_DE_TRABAJO.md` (respeta las dependencias de la Tabla 42). Scrum y los 6 sprints quedan solo en la tesis. | ✅ |
| D-18 | "Los próximos 7 días" del mockup | El plan Free solo da 5 días (`/data/2.5/forecast`). El panel muestra **"Los próximos 5 días"**; el resto del diseño de la lista no cambia. | ✅ |
| D-19 | Métricas "Sol fuerte (UV)" y "Presión" del panel | El índice UV no viene en `/data/2.5/weather` ni en `/forecast` (solo en One Call, excluido). La cuadrícula 3×2 queda Humedad · Viento · Va a llover (`pop`) · Llovió hoy · **Se siente** (`feels_like`) · **Nubes** (`clouds.all`), sin presión (término poco útil para el productor). | ✅ |
| D-20 | Umbral editable en "Mis avisos" (pantalla 23) | El diseño trae un deslizador "Frío que aguanta el café" para que el usuario cambie el umbral. La tesis fija umbrales en Firestore, solo escritos por funciones (RNF-19), y `DISENO_UI.md` no lo incluye. **No se implementa**; en su lugar se muestra el valor como dato informativo. | ✅ |
| D-21 | Supuestos técnicos del handoff de diseño | El README del diseño menciona One Call, WorkManager cada 3 h y Room/SQLite. Se sustituyen por la pila de la tesis: `/2.5` Free (D-09), ciclo en Cloud Functions (D-06) y persistencia sin conexión de Firestore + `shared_preferences` (D-12). | ✅ |
| D-22 | Inicialización de Firebase | Como la app es solo Android, `Firebase.initializeApp()` toma las opciones de `android/app/google-services.json`; no se usa `firebase_options.dart` (queda ignorado por git si `flutterfire` lo genera). El plugin `google-services` de Gradle se aplica solo si existe el JSON, así el proyecto compila y pasa `flutter analyze` sin claves. | ✅ |
| D-23 | Orden de la Etapa 1 | `plans/00` agrupa en HT-01 el tema, textos, rutas y componentes; `PLAN_DE_TRABAJO.md` los separa en su propia línea. Se sigue el plan de trabajo: HT-01 = dependencias, Android, secretos, estructura, entorno, utilidades y arranque. | ✅ |
| D-24 | Íconos | El diseño usa **Material Symbols Outlined** (peso 400) con íconos que `Icons` de Flutter no trae (`rainy`, `humidity_percentage`, `partly_cloudy_day`, `cloud_alert`…). Se agrega el paquete `material_symbols_icons` (fuente, sin costo; en release solo quedan los íconos usados). | ✅ |
| D-25 | Colores de PRECAUCIÓN (complementa D-04) | Se usan los tonos del diseño: borde #B26A00 (decorativo), texto **#4A2A00** e ícono **#8A4B00** sobre #FFF3D6; ambos superan 4.5:1 (hay prueba automática de contraste en `test/config/tema_test.dart`). En oscuro, #F6C453 sobre #3A2A08. | ✅ |
| D-26 | Sesión provisional | Hasta HU-02 no hay pantallas de acceso: `main.dart` arranca con `haySesion = true` para mostrar el contenedor con la barra inferior. La guarda (sin sesión → `/bienvenida`) ya está hecha y probada; HU-02 conecta el estado real del `AuthRepositorio`. | ✅ |
| D-27 | Pruebas y emuladores de `functions/` | `npm test` corre las pruebas unitarias (sin emulador). Las reglas se prueban aparte con `npm run test:reglas`, que levanta el emulador de Firestore con `emulators:exec` (proyecto `demo-agroclima-reglas`, sin tocar producción). Java: se usa el JBR de Android Studio (`JAVA_HOME`), no hace falta instalar otro. Runtime de funciones: Node 22. | ✅ |
| D-28 | Pruebas contra emuladores | `--dart-define=USAR_EMULADORES=true` conecta la app a los emuladores de auth y Firestore de la PC (10.0.2.2 desde el emulador de Android). Solo en depuración se permite HTTP hacia la PC (`src/debug/res/xml/red_emuladores.xml`). Las cuentas de prueba viven en `functions/seed/cuentas_prueba_emulador.json` y no existen en producción. | ✅ |
| D-29 | Google en HU-02 | El diseño pone "Entrar con Google" en la pantalla de inicio de sesión (05), no en el registro (06). El acceso con Google se implementa en HU-02 junto con esa pantalla; requiere activar el proveedor y volver a descargar `google-services.json`. | ✅ |
| D-30 | Prueba en teléfono físico | Por decisión de Steven se hace **al final del proyecto**, no por tarea. Las tareas se verifican en el emulador `AgroClima_API35` y se marcan terminadas al fusionarse; queda un solo pendiente general. | ✅ |

## Pendientes a revisar al final (no bloquean)

- Validar mensajes de alerta con productores (RC-01).
- Medir consumo real de OpenWeather y Firestore en la validación (RNF-21).
- Documentar el comportamiento de notificaciones por modelo de teléfono (RT-02).
