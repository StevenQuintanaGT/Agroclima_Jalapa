# Plan de trabajo

Orden en que se construye la aplicación. **No se trabaja por sprints ni con fechas**: se avanza etapa por
etapa y dentro de cada una tarea por tarea. El orden respeta las dependencias técnicas de la tesis
(Tabla 42): sin cuenta no hay parcelas, sin parcelas no hay clima, sin clima no hay alertas y sin alertas
no hay historial.

Estados: `[ ]` pendiente · `[~]` en curso · `[x]` terminada (cumple la Definición de listo de `CLAUDE.md` §6).
Al terminar cada etapa, generar un **APK de prueba** e instalarlo en un teléfono real.

---

## Etapa 1 — Base del proyecto y acceso · `plans/00`, `plans/01`
- [~] **HT-01** Configuración inicial Flutter (dependencias, Android minSdk 26, secretos, estructura)
- [~] Tema visual, componentes transversales base y navegación con barra inferior
- [~] **HT-02** Proyecto Firebase, reglas de seguridad e índices (con pruebas de reglas)
- [ ] **HU-01** Registro de usuario
- [ ] **HU-02** Sesión persistente (+ recuperación de contraseña y pantallas de permisos)

Resultado: splash, onboarding, registro, inicio de sesión, permisos y shell con los 5 destinos.

## Etapa 2 — Parcelas · `plans/02`
- [ ] Archivo de límites de Jalapa y validador geográfico (D-11)
- [ ] **HU-03** Ubicación de la parcela en el mapa
- [ ] **HU-04** Registro por ubicación del teléfono
- [ ] **HU-05** Nombre, cultivo y etapa (registro en 4 pasos)
- [ ] **HU-06** Listado, edición y eliminación (+ función de borrado en cascada)

## Etapa 3 — Clima de la parcela · `plans/03`
- [ ] Cliente OpenWeather (app y funciones)
- [ ] Función `adquirirClima` (guarda `pronosticos` y `condiciones` por celda)
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

(Espacio libre para anotar problemas encontrados — cuota, conectividad, comportamiento de algún teléfono —
y lo que se decidió.)
