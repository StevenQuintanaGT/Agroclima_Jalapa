# Requisitos (Capítulo IV de la tesis)

Fuente: Tablas 29–49. No cambiar códigos ni textos sin actualizar la tesis.

## 1. Épicas y módulos

| Épica | Módulo | Nombre | Historias |
|---|---|---|---|
| EP-01 | MOD-01 | Acceso y gestión de cuenta | HU-01, HU-02 |
| EP-02 | MOD-02 | Gestión geoespacial de parcelas | HU-03 a HU-06 |
| EP-03 | MOD-03 | Monitoreo meteorológico | HU-07, HU-08, HU-09, HU-15 |
| EP-04 | MOD-04 | Motor de alertas | HU-10, HU-11, HU-12 |
| EP-05 | MOD-05 | Historial y reportes | HU-13, HU-14, HU-16 |

## 2. Historias de usuario

| ID | Como… | Quiero… | Para… | Pts |
|---|---|---|---|---|
| HU-01 | Productor | Registrarme con mi correo o número de teléfono | Que mis parcelas y alertas queden en mi cuenta desde cualquier dispositivo | 3 |
| HU-02 | Productor registrado | Iniciar sesión y que la sesión permanezca activa | No autenticarme cada vez | 2 |
| HU-03 | Productor | Marcar la ubicación de mi parcela sobre un mapa | Que el clima sea el de mi terreno y no el de la cabecera | 8 |
| HU-04 | Productor | Registrar la parcela usando la ubicación del teléfono | No buscarla en el mapa estando en el terreno | 3 |
| HU-05 | Productor | Asignar nombre, cultivo y etapa a cada parcela | Que las alertas se ajusten a lo que produzco | 5 |
| HU-06 | Productor | Ver el listado de parcelas y editarlas o eliminarlas | Mantener la información al día | 5 |
| HU-07 | Productor | Ver temperatura, humedad, lluvia y viento actuales de mi parcela | Conocer la condición antes de salir | 5 |
| HU-08 | Productor | Consultar el pronóstico de los próximos días | Planificar la semana | 5 |
| HU-09 | Productor | Ver en el mapa dónde está lloviendo en el departamento | Saber si la lluvia viene hacia mi zona | 8 |
| HU-10 | Productor | Recibir una notificación cuando el pronóstico represente un riesgo | Actuar antes del daño | 13 |
| HU-11 | Productor | Abrir la alerta y ver qué la originó y qué parcela afecta | Saber cómo responder | 5 |
| HU-12 | Productor | Activar o desactivar tipos de alerta | No recibir lo que no afecta mi cultivo | 3 |
| HU-13 | Productor | Revisar las condiciones de días anteriores | Comparar cómo ha estado el tiempo | 8 |
| HU-14 | Productor | Ver las alertas recibidas antes | Llevar control de los eventos | 5 |
| HU-15 | Productor | Ver los últimos datos aunque no tenga señal | Consultar en zonas sin cobertura | 8 |
| HU-16 | Productor | Generar un resumen de condiciones y alertas de un período | Tener respaldo de lo ocurrido | 8 |

Habilitadores técnicos: **HT-01** Configuración inicial Flutter (3) · **HT-02** Proyecto Firebase y
reglas de seguridad (5) · **HT-03** Catálogo de umbrales (5) · **HT-04** Servicio de evaluación periódica (8).
Total de la pila: 115 puntos.

> Nota HU-16: el resumen del período se **exporta a PDF, Excel (.xlsx) o CSV** y también se puede
> **imprimir** desde el teléfono. La tesis solo menciona PDF; ver `DECISIONES.md` D-51.
> Criterios: normal — el archivo trae los mismos datos que se ven en Reportes; alterno — período sin
> alertas → el archivo lo dice; ante error — sin impresora o sin app para abrir el archivo → se ofrece
> compartirlo (WhatsApp, correo, Drive) en lugar de fallar.

> Nota HU-01: la tesis (§5.6.1) resuelve el acceso con **correo + contraseña o cuenta de Google**. El
> teléfono se guarda como dato de contacto (+502), no como método de acceso. Ver `DECISIONES.md` D-03.

## 3. Criterios de aceptación clave (§4.3.3 y §4.8.1)

Cada historia debe tener criterios en tres grupos: **normal**, **alterno** y **ante error**.
Sin criterios de error la historia no se empieza a programar.

- **Parcela por mapa (HU-03):** el mapa carga centrado en el departamento de Jalapa; se puede colocar el
  marcador en cualquier punto; al confirmar se guardan lat/lon con **≥ 4 decimales**; si el punto
  queda fuera del departamento se advierte y **no deja continuar**.
- **Clima actual (HU-07):** al abrir una parcela se ven temperatura, humedad, lluvia y viento de sus
  coordenadas con la **hora de última actualización**; si la consulta falla se muestran los últimos datos
  guardados **indicando que no están vigentes**. Sin conexión, igual; al volver la señal se sincroniza solo.
- **Alerta automática (HU-10):** el sistema evalúa periódicamente el pronóstico de cada parcela contra los
  umbrales de su cultivo y etapa; si se supera uno, notifica **solo al propietario** con el tipo de riesgo
  y el nombre de la parcela.

## 4. Reglas de negocio (Tabla 30)

| Código | Regla |
|---|---|
| RN-01 | Toda parcela está asociada a una cuenta; no hay registro anónimo. |
| RN-02 | Las coordenadas deben estar dentro del departamento de Jalapa. |
| RN-03 | Un usuario solo gestiona las parcelas que registró. |
| RN-04 | Las alertas son por parcela, no por municipio. |
| RN-05 | Los umbrales dependen del cultivo y la etapa; parcela sin cultivo → solo alertas generales. |
| RN-06 | La frecuencia de consulta se ajusta al plan gratuito, agrupando parcelas cercanas. |
| RN-07 | Las alertas son apoyo a la decisión y no sustituyen comunicados oficiales. |

## 5. Requerimientos no funcionales

| Código | Requerimiento | Cómo se verifica |
|---|---|---|
| RNF-01 | Acceso con Firebase Authentication; no se guardan contraseñas localmente. | Login válido/ inválido; no hay contraseña en disco. |
| RNF-02 | Cada documento de parcela, condición o alerta solo lo lee/modifica su dueño. | Pedir un documento ajeno por id → rechazado. |
| RNF-03 | Todo tráfico por HTTPS. | Inspeccionar tráfico. |
| RNF-04 | Claves fuera del código versionado. | Revisar repo. |
| RNF-05 | Solo permisos de ubicación y notificaciones, pedidos cuando se necesitan. | Manifiesto y primera ejecución. |
| RNF-06 | Pantalla principal en ≤ 3 s (2 GB RAM, Android 8.0). | Arranque en frío en físico. |
| RNF-07 | Condiciones de una parcela en ≤ 5 s con conexión estable. | 10 ejecuciones. |
| RNF-08 | Si la consulta falla o tarda, se muestra el dato en caché. | Servicio deshabilitado. |
| RNF-09 | APK ≤ 50 MB. | Build release. |
| RNF-10 | Notificación ≤ 5 min después de detectar el umbral. | Marcas de tiempo. |
| RNF-11 | No se descarga de nuevo lo que no cambió. | Consumo en una semana. |
| RNF-12 | Registro de parcela en máximo 4 pasos. | Contar pantallas. |
| RNF-13 | Textos en español sin terminología meteorológica técnica. | Revisión con productores. |
| RNF-14 | Cada alerta dice qué pasa y qué conviene hacer, no solo números. | Catálogo de mensajes. |
| RNF-15 | Área táctil suficiente; severidad por color **e** ícono. | Pantalla de 5", sol directo. |
| RNF-16 | La app avisa cuándo carga, cuándo el dato no está vigente y cuándo se completó una acción. | Recorrer flujos. |
| RNF-17 | Usuarios, parcelas, condiciones y alertas como documentos independientes. | Volumen creciente. |
| RNF-18 | Municipio como atributo de la parcela, no estructura fija. | Municipio de prueba sin cambiar modelo. |
| RNF-19 | Umbrales como configuración, no en el código. | Agregar cultivo sin recompilar. |
| RNF-20 | Presentación, negocio y datos desacoplados. | Cambiar proveedor de clima sin tocar UI. |
| RNF-21 | Crecer más allá de la validación implica plan de pago por uso. | Monitorear consumo. |
| RNF-22 | Android 8.0 o superior. | Instalar en versión mínima. |
| RNF-23 | Se adapta a tamaños y densidades sin desbordes. | 5" y mayores. |
| RNF-24 | Requiere servicios de Google Play (FCM y Mapas). | Dispositivo sin ellos. |
| RNF-25 | Distribución por APK directo durante la validación. | Instalar con orígenes desconocidos. |

## 6. Restricciones técnicas (Tabla 39)

RT-01 costo cero · RT-02 el dato es de la retícula del proveedor, no de la parcela (decirlo en la app) ·
RT-03 sin estaciones locales para contrastar · RT-04 equipo de una persona · RT-05 la entrega de
notificaciones depende del dispositivo → **toda alerta se replica dentro de la app y en el historial**.

## 7. Validaciones (Tabla 48)

| Código | Dónde | Validación | Si falla |
|---|---|---|---|
| VA-01 | Registro de parcela | Coordenadas dentro de Jalapa | Advierte y no deja continuar |
| VA-02 | Registro de parcela | Nombre no vacío ni repetido en la misma cuenta | Pide corregir |
| VA-03 | Registro de parcela | Área numérica y positiva | Marca el campo inválido |
| VA-04 | Registro de cuenta | Correo (o teléfono) con formato válido | Pide corregir |
| VA-05 | Registro de cuenta | Contraseña de **8 caracteres mínimo** (§5.6.1) | No deja completar |
| VA-06 | Datos del clima | Respuesta completa | Se descarta; queda el dato previo |
| VA-07 | Datos del clima | Valores dentro de rangos posibles para la región | Se descarta; no genera alerta |
| VA-08 | Datos del clima | Momento posterior al último dato guardado | Se descarta |

Rangos VA-07 (propuestos, en `functions/src/config.js` y `lib/config/constantes.dart`):
temperatura −5 a 45 °C · humedad 0 a 100 % · lluvia 0 a 200 mm/h · viento 0 a 200 km/h.

## 8. Restricciones de operación (Tabla 49)

RO-01 sin parcelas sin cuenta · RO-02 no se consultan parcelas ajenas · RO-03 **una sola notificación por
el mismo evento y parcela dentro de la ventana** (ver `UMBRALES.md` §5) · RO-04 no se guarda ubicación
fuera de las parcelas del propio productor (no se registra la ubicación del teléfono).

## 9. Riesgos que afectan el código (Tablas 50–53)

| Riesgo | Medida en el código |
|---|---|
| RT-01 cuota | Agrupar por celda, caché, periodicidad de 3 h, registrar número de llamadas por ciclo |
| RT-02 notificaciones poco confiables | Alertas replicadas en la app e historial |
| RT-03 imprecisión | Mostrar procedencia y hora del dato; alerta muestra variable y valor |
| RT-04 rendimiento del mapa | Capas solo cuando el usuario las activa; una a la vez |
| RR-01 umbrales mal calibrados | Umbrales en Firestore, editables sin recompilar |
| RC-01 lenguaje | Mensajes de acción revisables en `functions/src/mensajes.js` y `lib/config/textos.dart` |
| RC-03 expectativa | Aviso permanente "información de apoyo, no aviso oficial" |
