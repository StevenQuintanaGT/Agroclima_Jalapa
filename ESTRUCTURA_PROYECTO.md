# Estructura del proyecto

Refleja la organización descrita en la tesis (§5.3.2): directorios separados para modelos,
repositorios, servicios, pantallas por módulo, componentes reutilizables y utilidades, y el código
de las funciones de la nube en un directorio independiente.

Paquete Android: `gt.umg.agroclima_jalapa` · Nombre del proyecto Dart: `agroclima_jalapa`.

```
agroclima_jalapa/
├── CLAUDE.md                     # guía principal para Claude Code
├── AGENTS.md
├── ESTRUCTURA_PROYECTO.md        # este archivo
├── README.md                     # cómo instalar y correr (humano)
├── pubspec.yaml
├── analysis_options.yaml         # flutter_lints
├── .gitignore
├── firebase.json                 # emuladores, reglas, índices, funciones
├── .firebaserc
├── firestore.rules               # reglas de seguridad (ver docs/MODELO_DATOS.md §4)
├── firestore.indexes.json        # 2 índices compuestos sobre alertas
│
├── env/
│   ├── dev.example.json          # {"OPENWEATHER_API_KEY": ""}  (versionado)
│   └── dev.json                  # real, IGNORADO por git
│
├── assets/
│   ├── geo/jalapa_municipios.geojson   # límites de los 7 municipios (validación RN-02), geoBoundaries CC BY 3.0 IGO
│   ├── img/                            # logo, ilustraciones de onboarding y estados vacíos
│   └── fonts/                          # Roboto (si no se usa la del sistema)
│
├── android/                      # generado por flutter create; minSdk 26, canales de notificación
│
├── lib/
│   ├── main.dart                 # inicializa Firebase, persistencia, FCM y MultiProvider
│   ├── app.dart                  # MaterialApp.router, tema claro/oscuro
│   ├── firebase_options.dart     # generado por flutterfire, IGNORADO por git
│   │
│   ├── config/
│   │   ├── entorno.dart          # claves vía String.fromEnvironment
│   │   ├── rutas.dart            # go_router: rutas, guardas de sesión, shell con barra inferior
│   │   ├── textos.dart           # TODOS los textos visibles de la app
│   │   ├── constantes.dart       # vigencia del dato, tamaño de celda, límites, etc.
│   │   └── tema/
│   │       ├── colores.dart      # tokens de la Tabla 71 y semáforo Tabla 72
│   │       ├── tipografia.dart   # escala de la Tabla 73
│   │       ├── medidas.dart      # espaciado, radios y alturas táctiles
│   │       ├── colores_semaforo.dart # ThemeExtension del semáforo (claro/oscuro)
│   │       └── tema_app.dart     # ThemeData claro y oscuro (Material 3)
│   │
│   ├── modelos/                  # DTO del dominio: fromMap / toMap / copyWith
│   │   ├── enums.dart            # Municipio, Cultivo, Etapa, TipoRiesgo, NivelSeveridad (+ etiquetas UI)
│   │   ├── usuario.dart
│   │   ├── preferencia_alerta.dart
│   │   ├── parcela.dart
│   │   ├── condicion_meteorologica.dart
│   │   ├── pronostico_diario.dart
│   │   ├── pronostico_horario.dart   # solo en memoria/caché local para el panel
│   │   ├── umbral.dart
│   │   ├── alerta.dart
│   │   └── resultado.dart        # Resultado<T> con dato + vigente + error amigable
│   │
│   ├── repositorios/             # contrato abstracto + implementación en el mismo módulo
│   │   ├── auth_repositorio.dart            # + firebase_auth_repositorio.dart
│   │   ├── usuario_repositorio.dart         # perfil, preferencias, tokens FCM
│   │   ├── parcelas_repositorio.dart
│   │   ├── clima_repositorio.dart           # caché primero
│   │   ├── alertas_repositorio.dart         # + firestore_alertas_repositorio.dart (solo leida/atendida)
│   │   ├── umbrales_repositorio.dart        # solo lectura
│   │   ├── historial_repositorio.dart       # condiciones pasadas por rango de fechas
│   │   └── preferencias_locales_repositorio.dart # marcas del teléfono (bienvenida vista, permisos ofrecidos)
│   │
│   ├── servicios/                # lógica de negocio; no conocen widgets
│   │   ├── cuenta_servicio.dart             # registro: cuenta + perfil + preferencias
│   │   ├── estado_sesion.dart               # ValueNotifier de sesión para la guarda del enrutador
│   │   ├── openweather_cliente.dart         # FACHADA: arma peticiones, errores y traducción a dominio
│   │   ├── validacion_geografica.dart       # punto en polígono → municipio o null
│   │   ├── busqueda_lugares_servicio.dart   # "Buscar aldea o lugar" con el geocodificador del teléfono
│   │   ├── parcelas_servicio.dart           # registrar parcela (VA-01, VA-02, celda, dueño)
│   │   ├── celda_clima.dart                 # coordenadas → id de celda
│   │   ├── vigencia_servicio.dart           # ¿el dato guardado sigue vigente?
│   │   ├── conectividad_servicio.dart       # estado y cambios de conexión
│   │   ├── notificaciones_servicio.dart     # FCM: permiso, token, canales, abrir detalle
│   │   ├── alertas_servicio.dart            # activas/anteriores, orden por nivel, sin repetir, sin leer
│   │   ├── compartir_servicio.dart          # menú de compartir (WhatsApp) con share_plus
│   │   ├── avisos_servicio.dart             # "Mis avisos": preferencias y lo que aguanta el cultivo
│   │   ├── ubicacion_servicio.dart          # geolocator + permisos
│   │   └── reportes_servicio.dart           # resumen por período + PDF
│   │
│   ├── pantallas/                # una carpeta por módulo; cada pantalla con su *_vm.dart
│   │   ├── acceso/               # MOD-01: splash, onboarding, inicio_sesion, registro,
│   │   │                         #         recuperar_contrasena, permiso_ubicacion, permiso_notificaciones
│   │   ├── parcelas/             # MOD-02: registro_parcela (4 pasos), mis_parcelas, detalle_parcela
│   │   ├── clima/                # MOD-03: panel_principal, detalle_pronostico, mapa_clima
│   │   ├── alertas/              # MOD-04: centro_alertas, detalle_alerta, tarjeta_alerta, mis_avisos,
│   │   │                         #         apertura_alertas (abrir desde el aviso), contador_avisos (distintivo)
│   │   ├── reportes/             # MOD-05: reportes, historial, exportar_reporte
│   │   ├── perfil/               # perfil, ajustes, ayuda_glosario, acerca_de
│   │   └── shell/                # contenedor con la barra inferior de 5 destinos + pantalla_en_construccion
│   │
│   ├── componentes/              # CO-18 transversales, reutilizables
│   │   ├── chip_semaforo.dart    # color + ícono + palabra, siempre juntos
│   │   ├── icono_riesgo.dart     # ícono de cada tipo de riesgo
│   │   ├── tarjeta_metrica.dart
│   │   ├── boton_principal.dart  # 60 dp de alto, ancho completo
│   │   ├── boton_secundario.dart # 56 dp, neutro o destacado
│   │   ├── campo_texto.dart      # etiqueta arriba, palomita si es válido, "Ver" en contraseñas
│   │   ├── chip_seleccion.dart   # opción en píldora (municipios, etapas, unidades)
│   │   ├── tarjeta_opcion.dart   # tarjeta grande con ícono (cultivos)
│   │   ├── aviso_error.dart      # error general de formulario (ícono + color + palabras)
│   │   ├── ilustracion_provisional.dart # recuadro punteado hasta tener las ilustraciones
│   │   ├── logo_app.dart         # logotipo provisional
│   │   ├── barra_progreso_pasos.dart
│   │   ├── esqueleto_carga.dart
│   │   ├── aviso_no_vigente.dart # banner "No hay internet"
│   │   ├── marca_dato_guardado.dart # recuadro punteado "Datos del …"
│   │   ├── marco_punteado.dart   # borde punteado (marcas e ilustraciones pendientes)
│   │   ├── estado_vacio.dart
│   │   ├── estado_error.dart
│   │   └── aviso_apoyo.dart      # "Información de apoyo, no es aviso oficial" (RC-03)
│   │
│   └── utilidades/
│       ├── unidades.dart         # °C↔°F, manzana↔hectárea, m/s→km/h
│       ├── fechas.dart           # id yyyyMMdd en hora de Guatemala, textos relativos
│       ├── validadores.dart      # VA-02 a VA-05
│       └── errores.dart          # traducción de excepciones a textos llanos
│
├── test/                         # espejo de lib/ (unit + widget)
│
├── .github/workflows/ciclo-clima.yml  # tarea programada (cada 3 h) que ejecuta el ciclo (D-37)
├── .github/workflows/sembrar-umbrales.yml  # tarea manual: carga el catálogo de umbrales (D-45)
│
├── functions/                    # ciclo automático en JavaScript (Node LTS), lo ejecuta GitHub Actions
│   ├── package.json              # firebase-admin; jest para pruebas
│   ├── index.js                  # punto de entrada del ciclo (lo llama el workflow)
│   ├── src/
│   │   ├── config.js             # periodicidad, tamaño de celda, ventana de duplicados, rangos VA-07
│   │   ├── openweather.js        # cliente (fachada) del ciclo
│   │   ├── adquisicion.js        # CMP-08: recorre parcelas, agrupa por celda, guarda pronósticos/condiciones
│   │   ├── validacion.js         # VA-06..VA-08
│   │   ├── umbrales.js           # lee el catálogo vigente y filtra por parcela (§3)
│   │   ├── lluvia_del_dia.js     # lluvia acumulada del día desde las franjas (D-40)
│   │   ├── pronostico_diario.js  # franjas de 3 h → días (D-10)
│   │   ├── fechas.js             # id diario yyyyMMdd en hora de Guatemala
│   │   ├── evaluacion.js         # paso del ciclo: celdas actualizadas + historial → motor (HT-04)
│   │   ├── motor/
│   │   │   ├── evaluador.js      # CMP-09: aplica reglas y devuelve nivel por tipo de riesgo
│   │   │   ├── comparar.js       # operadores, orden de niveles, umbral que define el nivel
│   │   │   └── reglas/           # ESTRATEGIA: una regla por tipo de riesgo
│   │   │       ├── index.js      # registro tipoRiesgo → regla
│   │   │       ├── regla_diaria.js  # base de las variables diarias (con rachas de duracionDias)
│   │   │       ├── lluvia_intensa.js
│   │   │       ├── viento_fuerte.js
│   │   │       ├── sequia.js
│   │   │       ├── temperatura_baja.js
│   │   │       ├── temperatura_alta.js
│   │   │       └── humedad_alta.js
│   │   ├── alertas.js            # CO-13: mensaje, medida sugerida, control de duplicados
│   │   ├── notificaciones.js     # envío FCM respetando preferencias y horario de silencio
│   │   ├── mensajes.js           # plantillas de texto de alertas (lenguaje de acción)
│   │   └── limpieza.js           # borrado en cascada de parcela y de cuenta
│   ├── seed/umbrales.json        # catálogo inicial (Tabla 31)
│   ├── scripts/sembrar-umbrales.js
│   ├── scripts/simular-pronostico.js  # SOLO emulador: pronóstico extremo → alertas de prueba
│   └── test/
│
└── docs/
    ├── PLAN_DE_TRABAJO.md
    ├── REQUISITOS.md
    ├── MODELO_DATOS.md
    ├── UMBRALES.md
    ├── DISENO_UI.md
    ├── DECISIONES.md
    ├── diseno/                   # PNG de los 35 mockups (00-sistema-*, 01-splash … 34-error-servicio)
    └── plans/
        ├── 00-configuracion-inicial.md
        ├── 01-acceso-cuenta.md
        ├── 02-parcelas.md
        ├── 03-monitoreo-meteorologico.md
        ├── 04-motor-alertas.md
        └── 05-historial-reportes.md
```

## Dependencias de Flutter

Agregarlas con `flutter pub add <paquete>` para obtener la versión vigente compatible
(no copiar números de versión de memoria).

| Paquete | Uso |
|---|---|
| firebase_core, firebase_auth, cloud_firestore, firebase_messaging | Firebase |
| google_sign_in | Acceso con cuenta de Google |
| provider | Estado (MVVM) e inyección de dependencias |
| go_router | Navegación, guardas de sesión, barra inferior |
| flutter_map, latlong2 | Mapa de parcelas y capas (teselas de Esri, sin clave; D-37) |
| geocoding | "Buscar aldea o lugar" con el geocodificador del teléfono (D-34) |
| material_symbols_icons | Íconos Material Symbols del diseño (D-24) |
| geolocator, permission_handler | Ubicación y permisos |
| http | Cliente OpenWeather |
| connectivity_plus | Detección de conexión |
| flutter_local_notifications | Canales y notificaciones en primer plano |
| shared_preferences | Caché local pequeña (pronóstico horario, marca de onboarding) |
| intl | Fechas y números en `es` |
| fl_chart | Gráficas de pronóstico y reportes |
| pdf, printing | Exportar reporte a PDF |
| share_plus, url_launcher | Compartir por WhatsApp / abrir enlaces |
| **dev:** flutter_lints, mocktail | Análisis y pruebas |

## Dependencias de `functions/`

`firebase-admin` (Firestore, Auth y FCM con una cuenta de servicio; funciona con el plan Spark),
`jest` y `@firebase/rules-unit-testing` para pruebas. HTTP con `fetch` nativo de Node.
No se usa `firebase-functions`: el ciclo lo ejecuta GitHub Actions (D-37).
