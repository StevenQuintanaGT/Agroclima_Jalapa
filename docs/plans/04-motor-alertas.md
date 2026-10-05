# Plan 04 — Motor de alertas (MOD-04 · EP-04) · Etapa 4

> **Actualización D-37 (2026-10-03):** sin plan Blaze. Mapas con `flutter_map` + Esri (sin clave); el ciclo
> de `functions/` lo ejecuta GitHub Actions cada 3 h con `firebase-admin` (no Cloud Functions, Cloud Scheduler
> ni Secret Manager). Donde este plan diga `onSchedule`, `onDocumentDeleted`, `defineSecret`, "desplegar
> funciones" o Google Maps, aplicar `DECISIONES.md` D-37.

Historias: **HT-03** Catálogo de umbrales (5) · **HT-04** Evaluación periódica (8) · **HU-10** Notificación (13) ·
**HU-11** Detalle (5) · **HU-12** Preferencias (3).
Pantallas: 21 centro de alertas, 22 detalle, 23 mis avisos, 24 notificación, 35 sin alertas.
Referencia completa del algoritmo: `docs/UMBRALES.md`.

## Reparto nube / teléfono (§5.3.2)
- **Nube** (`functions/`): CO-11 catálogo, CO-12 reglas de evaluación, CO-13 generador de alertas y envío.
- **Teléfono** (`lib/pantallas/alertas/`): CO-14 centro de alertas y detalle, CO-15 preferencias.

## HT-03 — Catálogo
- [x] `functions/seed/umbrales.json` = `UMBRALES.md` §2; script `sembrar-umbrales.js` idempotente (usa `umbralId` como id).
- [x] `UmbralesRepositorio` en la app (solo lectura) para mostrar "lo que aguanta el cultivo" en el detalle.
- [x] Prueba: agregar un umbral nuevo en Firestore y verificar que el motor lo usa sin redeploy (RNF-19).

## HT-04 — Evaluación (CMP-09)
- [x] `motor/evaluador.js`: recibe parcela, pronósticos (5 días), historial de condiciones (últimos 20 días
      para sequía) y umbrales; aplica filtros de `UMBRALES.md` §3 y reglas §4.
- [x] Una regla por `tipoRiesgo` en `motor/reglas/` (Estrategia): agregar un criterio no toca las demás.
- [x] Se ejecuta al final de `adquirirClima` para las parcelas actualizadas. Catálogo leído una vez por ciclo.
- [x] Pruebas jest con casos de la Tabla 31: café con 3 días > 30 °C → crítica; maíz en floración con
      7 días secos → preventiva; frijol con mínima 17 °C → preventiva; hortalizas con 16 °C → nada;
      parcela sin cultivo con −1 °C → crítica (helada); lluvia 20 mm/h → preventiva.

## HU-10 — Generación y notificación (CMP-10)
- [ ] `alertas.js`: por cada resultado, control de duplicados (`UMBRALES.md` §5, índice 2), arma `mensaje`
      y `medidaSugerida` (`mensajes.js`), crea `alertas/{id}` con `leida:false, atendida:false`.
- [ ] `notificaciones.js`: aplica preferencias y silencio (§6), envía con `admin.messaging().sendEachForMulticast`
      a `tokensFcm`; título `"{PALABRA} · {parcelaNombre}"`, cuerpo = `mensaje`, `data: { alertaId, parcelaId }`,
      canal Android por nivel (`alertas_peligro` alta importancia, `alertas_precaucion`, `alertas_normal`).
      Quitar tokens inválidos. Guardar `notificada`.
- [ ] App: `NotificacionesServicio` crea los 3 canales, muestra notificaciones en primer plano con
      `flutter_local_notifications`, y al tocar (app abierta, en segundo plano o cerrada:
      `getInitialMessage` / `onMessageOpenedApp`) navega a `/alertas/:alertaId`.
- [ ] Latencia: el envío ocurre en la misma ejecución del ciclo (≤ 5 min tras la detección, RNF-10).

## HU-11 — Centro y detalle
- Centro (21): pestañas **Activos** (`fechaEvento` ≥ hoy) y **Anteriores**; ordenar por nivel (PELIGRO primero)
  y luego por fecha. Tarjeta: riesgo, parcela, cultivo, ventana en lenguaje hablado ("jueves en la tarde").
  Sin alertas activas (35): pantalla verde "Todo tranquilo en sus parcelas".
- Detalle (22): título con semáforo; **valor esperado vs. lo que aguanta el cultivo** (`valorEsperado` vs
  `valorUmbral`, D-14); frase resumen; qué hacer (`medidaSugerida`); botón "Ya tomé medidas" (`atendida: true`);
  "Avisar por WhatsApp" (`share_plus` con texto del aviso); `AvisoApoyo`. Al abrir → `leida: true`.
- La alerta se ve en la app aunque la notificación no haya llegado (RT-05).

## HU-12 — Mis avisos (23)
Interruptor por cada uno de los 6 tipos, selector de nivel mínimo (Precaución / Solo peligro),
horario de silencio nocturno ("De 10 de la noche a 5 de la mañana", PELIGRO siempre suena).
Escribe en `usuarios/{uid}/preferencias/{tipoRiesgo}`. Recordatorio en pantalla: "Aunque apague un aviso,
lo verá en Alertas."

## Criterios de aceptación
- Normal: se siembra un pronóstico de prueba que supera un umbral → llega la notificación y aparece en el centro.
- Alterno: con el tipo desactivado no suena pero aparece en el centro; en horario de silencio solo suena PELIGRO.
- Error: OpenWeather caído → no se generan alertas en ese ciclo; FCM falla → la alerta queda en la app;
  segundo ciclo con el mismo evento → no se duplica; el nivel sube → nueva alerta.

## Cómo probar sin esperar el clima real
Script `functions/scripts/simular-pronostico.js` (solo emulador) que escribe pronósticos extremos para una
parcela y ejecuta el evaluador. Nunca desplegar ese script a producción.
