# Diseño de la interfaz (§5.5 de la tesis)

Referencia visual obligatoria: el proyecto de **Claude Design** conectado a Claude Code (35 pantallas y sistema
visual). Antes de construir una pantalla, consulta su diseño ahí. Si una pantalla del código se ve distinta
al mockup, gana el mockup (salvo lo indicado en `DECISIONES.md`).

## 1. Principios

Material Design 3 adaptado a usuarios rurales. Cuatro principios:
1. Fondos claros que se lean bajo el sol.
2. Letra grande (cuerpo ≥ 16 sp).
3. **Una tarea por pantalla.**
4. Lenguaje sencillo, como habla el productor.

La app debe poder usarse con una mano, en el campo y sin ayuda después de una inducción corta.

## 2. Colores (Tabla 71) — `lib/config/tema/colores.dart`

| Token | Hex | Uso |
|---|---|---|
| primario | #2E7D32 | Botones principales, elementos activos, barra de navegación |
| primarioOscuro | #1B5E20 | Barras superiores y splash |
| contenedor | #C8E6C9 | Fondo de elementos seleccionados |
| acentoCielo | #0277BD | Íconos e ilustraciones del clima |
| fondo | #F7F6F2 | Fondo general (claro) |
| superficie | #FFFFFF | Tarjetas, campos, diálogos (claro) |
| texto | #1A1C19 | Texto principal (claro) |
| fondoOscuro | #10130F | Fondo general (oscuro) |
| superficieOscura | #1E231C | Tarjetas y campos (oscuro) |
| primarioTemaOscuro | #A5D6A7 | Botones y activos (oscuro) |

## 3. Semáforo de riesgo (Tabla 72) — `componentes/chip_semaforo.dart`

Siempre **color + ícono + palabra** juntos, igual en todas las pantallas.

| Nivel | Palabra | Color | Fondo | Ícono (Material Symbols) | Alerta |
|---|---|---|---|---|---|
| informativa | NORMAL | #2E7D32 | #E8F5E9 | `check_circle` | Informativa |
| preventiva | PRECAUCIÓN | #B26A00 → usar **#9A5B00** para texto | #FFF3D6 | `warning` | Preventiva |
| critica | PELIGRO | #B3261E | #FDE7E7 | `error` | Crítica |

Contraste: #B26A00 sobre #FFF3D6 da 3.84:1 (no cumple 4.5:1). **#9A5B00 da 4.92:1**. Ver `DECISIONES.md` D-04.
En tema oscuro se usan versiones aclaradas de los mismos tonos manteniendo ≥ 4.5:1.

## 4. Tipografía (Tabla 73) — Roboto, tamaños en sp (respetan el tamaño de letra del teléfono)

| Estilo | sp | Peso | Uso |
|---|---|---|---|
| datoDestacado | 64 | 900 | Temperatura actual en el panel |
| titular | 32 | 700 | Títulos de alertas y onboarding |
| titulo | 24 | 700 | Títulos de pantalla |
| subtitulo | 20 | 500 | Encabezados de sección |
| cuerpoGrande | 18 | 400 | Explicación de alerta o permiso |
| cuerpo | 16 | 400 | Texto general, campos, listas |
| etiqueta | 14 | 700 | Palabra del semáforo, etiquetas de campo |

Espaciado: 8 / 16 / 24 / 32 / 48 dp. Radios: 8 y 16 dp. Íconos siempre con su palabra.

## 5. Accesibilidad (Tabla 74) — se verifica en cada pantalla

| Directriz | Criterio |
|---|---|
| Tamaño de letra | Cuerpo ≥ 16 sp; no fijar `textScaleFactor` |
| Área táctil | ≥ 48×48 dp; campos y botones de **56 dp** de alto; botón principal a todo el ancho |
| Contraste | ≥ 4.5:1 texto/fondo |
| Color acompañado | El color nunca es la única señal |
| Íconos con texto | Barra inferior, capas del mapa, variables del clima |
| Lenguaje sencillo | "Va a llover fuerte" en vez de "precipitación acumulada" |
| Una tarea por pantalla | Registro de parcela en 4 pasos con barra de progreso |
| Confirmación clara | Acciones irreversibles con botones que dicen el resultado: "Sí, borrar" / "No, quedarme" |
| Sin señal | Nunca pantalla vacía: datos guardados con su fecha + "Intentar de nuevo" |

## 6. Lenguaje (RNF-13) — reglas para `lib/config/textos.dart`

- Trato de **usted** ("Marque su parcela", "Su correo").
- Palabras del campo: "¿Cómo va el cultivo?" (no "etapa fenológica"), "va a llover", "sol fuerte",
  "días sin lluvia", "helada".
- Sin anglicismos ni códigos de error. Errores dicen la causa probable y qué hacer.
- Unidades locales: **manzanas** por defecto (1 manzana = 0.6987 ha), °C por defecto.
- Aviso fijo en panel y detalle de alerta: "Esta información es de apoyo. No sustituye los avisos
  oficiales de INSIVUMEH o CONRED." (RN-07, RC-03).
- Indicar procedencia y hora: "Datos de OpenWeather · actualizado hace 20 min" (RT-02, RT-03).

## 7. Inventario de pantallas (35 diseños en Claude Design)

| # | Pantalla | Módulo | HU |
|---|---|---|---|
| 00-1..4 | Sistema: paleta, tipografía, componentes, iconografía | — | — |
| 01 | Splash: logo, "Jalapa", "El clima de su parcela, antes de que pase" | MOD-01 | — |
| 02–04 | Onboarding (3): marque su parcela · vea el clima de ahí · reciba avisos antes; el último botón dice "Empezar" | MOD-01 | — |
| 05 | Inicio de sesión: correo, contraseña con "Ver", Google, crear cuenta | MOD-01 | HU-02 |
| 06 | Registro: nombre, teléfono +502, correo, contraseña, términos | MOD-01 | HU-01 |
| 07 | Recuperar contraseña (confirma en la misma pantalla) | MOD-01 | — |
| 08 | Permiso de ubicación (explica antes del diálogo; "Ahora no") | MOD-01/02 | HU-04 |
| 09 | Permiso de notificaciones ("Ahora no") | MOD-01/04 | HU-10 |
| 10 | Parcela paso 1: nombre + municipio (7 botones visibles) | MOD-02 | HU-05 |
| 11 | Paso 2: cultivo + "¿Cómo va el cultivo?" | MOD-02 | HU-05 |
| 12 | Paso 3: mapa con pin, "Usar mi ubicación", coordenadas, altura, tamaño (mz/ha) | MOD-02 | HU-03, HU-04 |
| 13 | Paso 4: revisión, cada dato con su botón "Cambiar" | MOD-02 | HU-05 |
| 14 | Mis parcelas: tarjetas con municipio, cultivo, temperatura, semáforo; deslizar para editar/borrar | MOD-02 | HU-06 |
| 15 | Detalle de parcela / borrar ("Sí, borrar" / "No, quedarme", advierte pérdida de historial) | MOD-02 | HU-06 |
| 16 | Parcelas vacío: un botón para registrar la primera | MOD-02 | HU-06 |
| 17 | Panel principal claro: riesgo del día → temperatura grande → humedad/viento/lluvia → por horas → próximos días → consejo | MOD-03 | HU-07, HU-08 |
| 18 | Panel principal oscuro (mismo orden y semáforo) | MOD-03 | HU-07 |
| 19 | Detalle de pronóstico: curva de temperatura, barras de lluvia por franja con frase ("lluvia ligera"), viento, humedad, salida/puesta del sol | MOD-03 | HU-08 |
| 20 | Mapa del clima: pines de parcelas, capas lluvia/nubes/calor/viento con ícono y nombre, leyenda "Qué significan los colores" | MOD-03 | HU-09 |
| 21 | Centro de alertas: pestañas Activos / Anteriores, ordenadas por nivel (PELIGRO primero) | MOD-04 | HU-11, HU-14 |
| 22 | Detalle de alerta: esperado vs. lo que aguanta el cultivo, frase resumen, qué hacer, "Ya tomé medidas", compartir por WhatsApp | MOD-04 | HU-11 |
| 23 | Mis avisos: interruptor por riesgo, nivel mínimo, no molestar de noche (salvo PELIGRO) | MOD-04 | HU-12 |
| 24 | Notificación del sistema: empieza con la palabra del semáforo y la parcela | MOD-04 | HU-10 |
| 25 | Reportes: 7/30 días, 4 indicadores (días con lluvia, noche más fría, lluvia acumulada, avisos de peligro) + gráficas | MOD-05 | HU-16 |
| 26 | Historial día por día, filtros Todo / Con lluvia / Con aviso | MOD-05 | HU-13 |
| 27 | Guardar o enviar el reporte: período (7/30 días/elegir), formato **PDF / Excel / CSV** (tarjetas con ícono, nombre y para qué sirve), botones "Compartir" e "Imprimir" (D-51) | MOD-05 | HU-16 |
| 28 | Perfil: datos, parcelas, avisos, ajustes, ayuda, cerrar sesión | Perfil | — |
| 29 | Ajustes: °C/°F, manzanas/ha, tema oscuro, ahorro de datos; eliminar cuenta al final | Perfil | — |
| 30 | Ayuda y glosario | Perfil | — |
| 31 | Acerca de: de dónde vienen los datos | Perfil | — |
| 32 | Sin conexión: datos guardados apagados + fecha + "Intentar de nuevo" | Transversal | HU-15 |
| 33 | Carga: esqueleto con forma del panel + frase | Transversal | RNF-16 |
| 34 | Error de servicio: causa probable en lenguaje sencillo | Transversal | RNF-16 |
| 35 | Sin alertas: en verde, como buena noticia | Transversal | — |

## 8. Navegación (Figura 36)

**Primera vez (lineal):** Splash → Onboarding (3) → Registro / Inicio de sesión → Permiso de ubicación →
Permiso de notificaciones → Registro de primera parcela (4 pasos) → Panel principal.

**Usos siguientes:** Splash → (sesión activa) → Panel principal.

**Dentro de la app:** barra inferior de 5 destinos con ícono y palabra:
`Inicio` (panel) · `Mapa` · `Alertas` · `Reportes` · `Perfil`. Desde cada uno se llega a sus detalles
(pronóstico, detalle de alerta, historial, ajustes…).

**Notificación:** única entrada que no pasa por la barra; abre directo `alertas/:alertaId`
(también con la app cerrada o en segundo plano).

Rutas sugeridas (go_router): `/splash`, `/bienvenida`, `/entrar`, `/registro`, `/recuperar`,
`/permisos/ubicacion`, `/permisos/avisos`, `/parcelas/nueva`, `/inicio`, `/inicio/pronostico/:parcelaId`,
`/mapa`, `/alertas`, `/alertas/:alertaId`, `/alertas/preferencias`, `/reportes`, `/reportes/historial/:parcelaId`,
`/perfil`, `/perfil/parcelas`, `/perfil/parcelas/:parcelaId`, `/perfil/ajustes`, `/perfil/ayuda`, `/perfil/acerca`.
Si hay varias parcelas, el panel tiene un selector de parcela arriba.
