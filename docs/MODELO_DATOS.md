# Modelo de datos — Cloud Firestore (§5.4 y §5.6 de la tesis)

Firestore no impone esquema: **este documento es el esquema**. Los nombres de campos y los valores de
enumeración son exactamente estos, en la app (`lib/modelos/`) y en `functions/`.

## 1. Estructura

```
usuarios/{uid}
    └── preferencias/{tipoRiesgo}
parcelas/{parcelaId}
    ├── condiciones/{yyyyMMdd}
    └── pronosticos/{yyyyMMdd}
alertas/{alertaId}
umbrales/{umbralId}
```

- Condiciones y pronósticos son subcolecciones porque siempre se piden por parcela.
- Alertas es colección aparte porque el centro de avisos las muestra juntas para todas las parcelas.
- Umbrales es colección aparte, solo lectura para la app (RNF-19).
- Los ids de condiciones y pronósticos son la **fecha `yyyyMMdd` en hora de Guatemala**: una segunda
  escritura del mismo día sobrescribe (no duplica) y el rango se obtiene ordenando por id.

## 2. Enumeraciones (valor guardado → etiqueta en pantalla)

**Municipio** (`municipio`)
`jalapa` → Jalapa · `sanPedroPinula` → San Pedro Pinula · `sanLuisJilotepeque` → San Luis Jilotepeque ·
`sanManuelChaparron` → San Manuel Chaparrón · `sanCarlosAlzatate` → San Carlos Alzatate ·
`monjas` → Monjas · `mataquescuintla` → Mataquescuintla

**Cultivo** (`cultivo`) — vacío = sin cultivo (solo umbrales generales)
`maiz` → Maíz · `frijol` → Frijol · `cafe` → Café · `hortalizas` → Hortalizas

**Etapa** (`etapa`) — vacío = sin etapa
`siembra` → Siembra · `desarrolloVegetativo` → Creciendo · `floracion` → Floreando ·
`llenado` → Llenando el grano o la vaina · `cosecha` → Cosecha

**TipoRiesgo** (`tipoRiesgo`)
`lluviaIntensa` → Lluvia fuerte · `vientoFuerte` → Viento fuerte · `sequia` → Días sin lluvia ·
`temperaturaBaja` → Frío · `temperaturaAlta` → Calor · `humedadAlta` → Mucha humedad

**NivelSeveridad** (`nivel`, `nivelMinimo`)
`informativa` → NORMAL (verde) · `preventiva` → PRECAUCIÓN (ámbar) · `critica` → PELIGRO (rojo)

(Las etiquetas definitivas viven en `lib/config/textos.dart`; ver `DECISIONES.md` D-01 y D-02.)

## 3. Diccionario de datos

### usuarios/{uid}  (Tabla 64)
| Campo | Tipo | Oblig. | Defecto | Descripción |
|---|---|---|---|---|
| uid | string | sí | — | = uid de Firebase Auth (id del documento) |
| nombre | string | sí | — | Nombre del productor |
| telefono | string | no | "" | Con código de país, ej. `+50245829385` |
| correo | string | sí | — | Correo de la cuenta |
| fechaRegistro | timestamp | sí | serverTimestamp | Alta de la cuenta |
| unidadTemperatura | string | sí | `C` | `C` o `F` |
| unidadArea | string | sí | `manzana` | `manzana` o `hectarea` |
| temaOscuro | bool | sí | false | |
| ahorroDatos | bool | sí | false | Restringe la capa del mapa y amplía la vigencia del dato |
| tokensFcm | array<string> | no | [] | Un token por teléfono con sesión activa |

### usuarios/{uid}/preferencias/{tipoRiesgo}  (Tabla 65)
Un documento por tipo de riesgo (6). Se crean con valores por defecto al registrar la cuenta.
| Campo | Tipo | Oblig. | Defecto | Descripción |
|---|---|---|---|---|
| tipoRiesgo | string | sí | — | = id del documento |
| activa | bool | sí | true | ¿Quiere notificación de este tipo? |
| nivelMinimo | string | sí | `preventiva` | Nivel desde el cual se envía |
| silencioDesde | string | no | `22:00` | Hora local sin avisos (salvo PELIGRO) |
| silencioHasta | string | no | `05:00` | Hora en que se reanuda |

Las preferencias **filtran el envío, no la generación**: la alerta se registra aunque no se notifique.

### parcelas/{parcelaId}  (Tabla 66)
| Campo | Tipo | Oblig. | Defecto | Descripción |
|---|---|---|---|---|
| parcelaId | string | sí | id automático | = id del documento |
| usuarioId | string | sí | — | Dueño; base del control de acceso |
| nombre | string | sí | — | Único dentro de la cuenta (VA-02) |
| municipio | string | sí | — | Enumeración Municipio (lo devuelve el validador geográfico) |
| cultivo | string | no | "" | Enumeración Cultivo |
| etapa | string | no | "" | Enumeración Etapa |
| ubicacion | geopoint | sí | — | Lat/lon, ≥ 4 decimales |
| altitud | int | no | null | msnm |
| area | double | no | null | > 0 (VA-03) |
| unidadArea | string | no | `manzana` | Unidad en que se escribió el área |
| celdaClima | string | sí | calculado | Ver `plans/03` §2 |
| activa | bool | sí | true | Participa en el ciclo automático |
| fechaRegistro | timestamp | sí | serverTimestamp | |
| fechaActualizacion | timestamp | sí | serverTimestamp | En cada escritura |

### parcelas/{id}/condiciones/{yyyyMMdd}  (Tabla 67)
| Campo | Tipo | Oblig. | Defecto | Descripción |
|---|---|---|---|---|
| fecha | string | sí | — | `yyyyMMdd` (= id) |
| fechaHora | timestamp | sí | — | Momento de la observación (UTC) |
| temperatura | double | sí | — | °C |
| humedadRelativa | double | sí | — | % |
| precipitacion | double | sí | 0 | mm acumulados del día |
| velocidadViento | double | sí | — | km/h |
| origen | string | sí | `ciclo` | `ciclo` o `consulta` |
| vigente | bool | sí | true | Dentro de su intervalo de validez |

### parcelas/{id}/pronosticos/{yyyyMMdd}  (Tabla 68) — único insumo del motor
| Campo | Tipo | Oblig. | Defecto | Descripción |
|---|---|---|---|---|
| fecha | string | sí | — | Día proyectado (= id) |
| temperaturaMinima | double | sí | — | °C |
| temperaturaMaxima | double | sí | — | °C |
| precipitacionHora | double | sí | 0 | Intensidad media máxima del día, mm/h |
| acumuladoDia | double | sí | 0 | mm totales del día |
| velocidadViento | double | sí | — | Máxima del día, km/h |
| humedadRelativa | double | sí | — | Promedio del día, % |
| fechaConsulta | timestamp | sí | serverTimestamp | Cuándo se obtuvo |

### alertas/{alertaId}  (Tabla 69)
| Campo | Tipo | Oblig. | Defecto | Descripción |
|---|---|---|---|---|
| alertaId | string | sí | id automático | |
| usuarioId | string | sí | — | Destinatario |
| parcelaId | string | sí | — | Parcela afectada |
| tipoRiesgo | string | sí | — | |
| nivel | string | sí | — | `informativa` / `preventiva` / `critica` |
| valorEsperado | double | sí | — | Valor pronosticado que la activó |
| valorUmbral | double | sí | — | Criterio contra el que se comparó |
| mensaje | string | sí | — | Texto en lenguaje de acción (RNF-14) |
| medidaSugerida | string | no | "" | Qué conviene hacer, según riesgo y cultivo |
| fechaGeneracion | timestamp | sí | serverTimestamp | |
| fechaEvento | timestamp | sí | — | Día de la condición proyectada (00:00 hora local) |
| leida | bool | sí | false | Abrió el detalle |
| atendida | bool | sí | false | "Ya tomé medidas" |

Campos adicionales **permitidos** (desnormalizados para mostrar sin otra lectura; ver `DECISIONES.md` D-05):
`parcelaNombre` (string), `cultivo` (string), `diasConsecutivos` (int, para sequía y calor),
`notificada` (bool, si se envió por FCM).
Una alerta **no se modifica** después de creada, salvo `leida` y `atendida`.

### umbrales/{umbralId}  (Tabla 70)
| Campo | Tipo | Oblig. | Defecto | Descripción |
|---|---|---|---|---|
| umbralId | string | sí | — | Legible, ej. `tmax_cafe_preventiva` |
| variable | string | sí | — | `precipitacionHora`, `velocidadViento`, `diasSecos`, `temperaturaMinima`, `temperaturaMaxima`, `humedadRelativa` |
| cultivo | string | no | "" | Vacío = general |
| etapa | string | no | "" | Vacío = todas |
| operador | string | sí | — | `mayor`, `mayorIgual`, `menor`, `menorIgual` |
| valor | double | sí | — | |
| duracionDias | int | no | 1 | Días consecutivos que deben cumplirlo |
| nivel | string | sí | — | |
| fuente | string | sí | — | Cita APA corta |
| vigente | bool | sí | true | |

Adicional permitido: `tipoRiesgo` (string) para no derivarlo de la variable.
El catálogo inicial está en `docs/UMBRALES.md` y `functions/seed/umbrales.json`.

## 4. Índices compuestos (`firestore.indexes.json`)

1. `alertas`: `usuarioId ASC, fechaGeneracion DESC` — centro de avisos.
2. `alertas`: `parcelaId ASC, tipoRiesgo ASC, fechaEvento ASC` — control de duplicados.

Lo demás se resuelve con índices automáticos (`parcelas where usuarioId ==`, subcolecciones por id).

## 5. Reglas de seguridad (Tabla 75) — base para `firestore.rules`

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    function autenticado() { return request.auth != null; }
    function esUsuario(uid) { return autenticado() && request.auth.uid == uid; }
    function duenoParcela(pid) {
      return get(/databases/$(db)/documents/parcelas/$(pid)).data.usuarioId;
    }

    match /usuarios/{uid} {
      allow read: if esUsuario(uid);
      allow create: if esUsuario(uid) && request.resource.data.uid == uid;
      allow update: if esUsuario(uid) && request.resource.data.uid == resource.data.uid;
      allow delete: if false;                      // la cuenta se borra con una función (cascada)

      match /preferencias/{tipo} {
        allow read, write: if esUsuario(uid);
      }
    }

    match /parcelas/{pid} {
      allow read, delete: if esUsuario(resource.data.usuarioId);
      allow create: if esUsuario(request.resource.data.usuarioId);
      allow update: if esUsuario(resource.data.usuarioId)
                    && request.resource.data.usuarioId == resource.data.usuarioId;

      match /condiciones/{fecha} {
        allow read: if esUsuario(duenoParcela(pid));
        allow create, update: if esUsuario(duenoParcela(pid))
                              && request.resource.data.origen == 'consulta';
        allow delete: if false;
      }
      match /pronosticos/{fecha} {
        allow read: if esUsuario(duenoParcela(pid));
        allow write: if false;                     // solo funciones de la nube
      }
    }

    match /alertas/{aid} {
      allow read: if esUsuario(resource.data.usuarioId);
      allow update: if esUsuario(resource.data.usuarioId)
                    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['leida', 'atendida']);
      allow create, delete: if false;              // solo funciones de la nube
    }

    match /umbrales/{id} {
      allow read: if autenticado();
      allow write: if false;
    }
  }
}
```

Las funciones de la nube usan Admin SDK (cuenta de servicio) y no pasan por estas reglas.
Las consultas de la app **siempre** deben filtrar por `usuarioId == uid` o las reglas las rechazan.

Pruebas obligatorias de reglas (emulador, `@firebase/rules-unit-testing`): leer parcela ajena → rechazo;
crear parcela con `usuarioId` ajeno → rechazo; escribir pronóstico desde el cliente → rechazo;
cambiar `mensaje` de una alerta → rechazo; marcar `leida` propia → permitido.

## 6. Borrado en cascada

- **Eliminar parcela** (desde la app se borra el documento): en la siguiente vuelta del ciclo de GitHub
  Actions, `limpiarParcelasBorradas` (`functions/src/limpieza.js`) borra `condiciones`, `pronosticos` y las
  `alertas` con ese `parcelaId` (D-37, D-38; reemplaza a `onDocumentDeleted`, que exige Blaze).
- **Eliminar cuenta** (Tabla 76): función invocable `eliminarCuenta` borra perfil, preferencias, parcelas
  (con su cascada) y alertas, y luego el usuario de Auth, lo que cierra la sesión en todos los teléfonos.

## 7. Operación sin conexión

`FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true, cacheSizeBytes: ...)`.
Las lecturas devuelven la copia local si no hay señal; las escrituras quedan pendientes y se sincronizan
solas. Para distinguir dato local de servidor usar `snapshot.metadata.isFromCache`.
Al **cerrar sesión**: quitar el token FCM de `tokensFcm`, `terminate()` + `clearPersistence()`.
