import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../pantallas/acceso/bienvenida_pantalla.dart';
import '../pantallas/acceso/bienvenida_vm.dart';
import '../pantallas/acceso/inicio_sesion_pantalla.dart';
import '../pantallas/acceso/inicio_sesion_vm.dart';
import '../pantallas/acceso/permiso_pantalla.dart';
import '../pantallas/acceso/permiso_vm.dart';
import '../pantallas/acceso/recuperar_contrasena_pantalla.dart';
import '../pantallas/acceso/recuperar_contrasena_vm.dart';
import '../pantallas/acceso/registro_pantalla.dart';
import '../pantallas/acceso/registro_vm.dart';
import '../pantallas/acceso/splash_pantalla.dart';
import '../pantallas/perfil/perfil_pantalla.dart';
import '../pantallas/perfil/perfil_vm.dart';
import '../pantallas/shell/pantalla_en_construccion.dart';
import '../pantallas/shell/shell_pantalla.dart';
import '../repositorios/preferencias_locales_repositorio.dart';
import '../servicios/cuenta_servicio.dart';
import '../servicios/notificaciones_servicio.dart';
import '../servicios/ubicacion_servicio.dart';
import 'tema/colores.dart';
import 'textos.dart';

/// Rutas de la app (docs/DISENO_UI.md §8). Se agregan a medida que se
/// construyen las pantallas.
class Rutas {
  Rutas._();

  static const String splash = '/';
  static const String bienvenida = '/bienvenida';
  static const String entrar = '/entrar';
  static const String registro = '/entrar/registro';
  static const String recuperar = '/entrar/recuperar';
  static const String permisoUbicacion = '/permisos/ubicacion';
  static const String permisoAvisos = '/permisos/avisos';
  static const String inicio = '/inicio';
  static const String mapa = '/mapa';
  static const String alertas = '/alertas';
  static const String reportes = '/reportes';
  static const String perfil = '/perfil';

  /// Rutas que se ven sin sesión (acceso e incorporación).
  static const Set<String> publicas = {
    splash,
    bienvenida,
    entrar,
    registro,
    recuperar,
  };
}

/// Decide a dónde va el productor según su sesión (flujos 1 y 2 de la
/// Figura 36). Separada del enrutador para probarla sola.
@visibleForTesting
String? destinoSegunSesion({
  required String ubicacion,
  required bool haySesion,
  required PreferenciasLocalesRepositorio preferencias,
}) {
  if (ubicacion == Rutas.splash) return null;
  final esPublica = Rutas.publicas.contains(ubicacion);
  if (!haySesion) {
    if (esPublica) return null;
    return preferencias.bienvenidaVista ? Rutas.entrar : Rutas.bienvenida;
  }
  if (esPublica) {
    return preferencias.permisosOfrecidos
        ? Rutas.inicio
        : Rutas.permisoUbicacion;
  }
  return null;
}

/// Crea el enrutador con la guarda de sesión. [haySesion] lo aporta
/// `EstadoSesion` (Firebase Auth).
GoRouter crearEnrutador({
  required ValueListenable<bool> haySesion,
  required PreferenciasLocalesRepositorio preferencias,
}) {
  return GoRouter(
    initialLocation: Rutas.splash,
    refreshListenable: haySesion,
    redirect: (context, estado) => destinoSegunSesion(
      ubicacion: estado.matchedLocation,
      haySesion: haySesion.value,
      preferencias: preferencias,
    ),
    routes: [
      GoRoute(
        path: Rutas.splash,
        builder: (context, estado) => const SplashPantalla(),
      ),
      GoRoute(
        path: Rutas.bienvenida,
        builder: (context, estado) => ChangeNotifierProvider(
          create: (_) => BienvenidaVm(preferencias),
          child: const BienvenidaPantalla(),
        ),
      ),
      GoRoute(
        path: Rutas.entrar,
        builder: (context, estado) => ChangeNotifierProvider(
          create: (context) => InicioSesionVm(context.read<CuentaServicio>()),
          child: const InicioSesionPantalla(),
        ),
        routes: [
          GoRoute(
            path: 'registro',
            builder: (context, estado) => ChangeNotifierProvider(
              create: (context) => RegistroVm(context.read<CuentaServicio>()),
              child: const RegistroPantalla(),
            ),
          ),
          GoRoute(
            path: 'recuperar',
            builder: (context, estado) => ChangeNotifierProvider(
              create: (context) =>
                  RecuperarContrasenaVm(context.read<CuentaServicio>()),
              child: const RecuperarContrasenaPantalla(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Rutas.permisoUbicacion,
        builder: (context, estado) => ChangeNotifierProvider(
          create: (context) => PermisoVm(
            pedirPermiso: context.read<UbicacionServicio>().pedirPermiso,
            preferencias: preferencias,
            esUltimo: false,
          ),
          child: PermisoPantalla(
            icono: Symbols.my_location,
            colorIcono: Colores.primario,
            colorFondo: Colores.contenedorClaro,
            colorBorde: Colores.bordeIlustracionVerde,
            titulo: Textos.permisoUbicacionTitulo,
            detalle: Textos.permisoUbicacionDetalle,
            textoPermitir: Textos.permitir,
            alTerminar: () => context.go(Rutas.permisoAvisos),
          ),
        ),
      ),
      GoRoute(
        path: Rutas.permisoAvisos,
        builder: (context, estado) => ChangeNotifierProvider(
          create: (context) => PermisoVm(
            pedirPermiso: context.read<NotificacionesServicio>().pedirPermiso,
            preferencias: preferencias,
            esUltimo: true,
          ),
          child: PermisoPantalla(
            icono: Symbols.notifications_active,
            colorIcono: Colores.precaucionIcono,
            colorFondo: Colores.precaucionFondo,
            colorBorde: Colores.bordeIlustracionAmbar,
            titulo: Textos.permisoAvisosTitulo,
            detalle: Textos.permisoAvisosDetalle,
            textoPermitir: Textos.permitirAvisos,
            // TODO(HU-05): seguir al registro de la primera parcela.
            alTerminar: () => context.go(Rutas.inicio),
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, estado, navegacion) =>
            ShellPantalla(navegacion: navegacion),
        branches: [
          _rama(Rutas.inicio, Textos.navInicio),
          _rama(Rutas.mapa, Textos.navMapa),
          _rama(Rutas.alertas, Textos.navAlertas),
          _rama(Rutas.reportes, Textos.navReportes),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rutas.perfil,
                builder: (context, estado) => ChangeNotifierProvider(
                  create: (context) => PerfilVm(context.read<CuentaServicio>()),
                  child: const PerfilPantalla(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

StatefulShellBranch _rama(String ruta, String titulo) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: ruta,
      builder: (context, estado) => PantallaEnConstruccion(titulo: titulo),
    ),
  ],
);
