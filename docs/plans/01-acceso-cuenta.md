# Plan 01 — Acceso y gestión de cuenta (MOD-01 · EP-01) · Etapa 1

Historias: **HU-01** Registro (3) · **HU-02** Sesión persistente (2).
Pantallas: 01 splash, 02–04 onboarding, 05 inicio de sesión, 06 registro, 07 recuperar contraseña,
08 permiso de ubicación, 09 permiso de notificaciones. (Perfil y ajustes se completan en la Etapa 6.)

## Componentes
- **CO-01** pantallas de acceso y perfil (`lib/pantallas/acceso/`), cada una con su `*_vm.dart`.
- **CO-02** `AuthRepositorio` (contrato) + `FirebaseAuthRepositorio`:
  `registrar(nombre, telefono, correo, contrasena)`, `iniciarSesion(correo, contrasena)`,
  `iniciarConGoogle()`, `cerrarSesion()`, `recuperarContrasena(correo)`, `Stream<Usuario?> estadoSesion`.
- `UsuarioRepositorio`: crear/leer/actualizar `usuarios/{uid}`, crear las 6 `preferencias` por defecto,
  agregar/quitar token FCM.
- `NotificacionesServicio` (base): pedir permiso, obtener token, escuchar `onTokenRefresh`.

## Flujo
1. Splash: si hay sesión → `/inicio`; si no, y no ha visto onboarding (flag en `shared_preferences`) → `/bienvenida`; si ya lo vio → `/entrar`.
2. Registro: crea usuario en Auth → crea `usuarios/{uid}` con defectos (Tabla 64) → crea preferencias
   (Tabla 65) → guarda token FCM → permisos → registro de primera parcela.
3. Google: si es primera vez, se crea el documento de usuario con nombre y correo de Google (teléfono vacío).
4. Inicio de sesión: al entrar, agregar token FCM a `tokensFcm` (`arrayUnion`) (Tabla 76).
5. Cierre de sesión: `arrayRemove` del token, borrar token local de FCM, `signOut`, limpiar persistencia.
6. Permisos (pantallas 08 y 09): explican para qué sirve **antes** del diálogo del sistema; "Ahora no"
   continúa sin pedir. Si luego se necesita ubicación, se vuelve a explicar.

## Validaciones
- VA-04 correo con formato válido; teléfono opcional con formato `+502` y 8 dígitos.
- VA-05 contraseña ≥ 8 caracteres; botón "Ver" para mostrarla.
- Nombre obligatorio.

## Errores → texto llano (`utilidades/errores.dart`)
| Código Firebase | Texto |
|---|---|
| email-already-in-use | "Ese correo ya tiene cuenta. ¿Quiere entrar?" |
| invalid-credential / wrong-password / user-not-found | "El correo o la contraseña no coinciden." |
| weak-password | "La contraseña debe tener al menos 8 letras o números." |
| network-request-failed | "No hay señal. Intente de nuevo cuando tenga internet." |
| too-many-requests | "Hubo muchos intentos. Espere un momento y vuelva a probar." |
| otro | "No se pudo completar. Intente de nuevo." |

## Criterios de aceptación
- Normal: crear cuenta, cerrar la app, abrirla → entra directo al panel (HU-02).
- Alterno: entrar con Google; recuperar contraseña muestra confirmación en la misma pantalla.
- Error: sin señal en el registro → mensaje llano, no se pierde lo escrito; credenciales malas → mensaje llano.
- No se guarda la contraseña en el teléfono (RNF-01).

## Pruebas
Unitarias de validadores y de los ViewModels con `AuthRepositorio` simulado (mocktail);
de widget para registro (errores de campo visibles).
