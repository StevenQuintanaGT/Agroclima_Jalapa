import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../componentes/boton_principal.dart';
import '../pantallas/acceso/registro_pantalla.dart';
import '../pantallas/acceso/registro_vm.dart';
import '../pantallas/shell/pantalla_en_construccion.dart';
import '../pantallas/shell/shell_pantalla.dart';
import '../servicios/cuenta_servicio.dart';
import 'textos.dart';

/// Rutas de la app (docs/DISENO_UI.md §8). Se agregan a medida que se
/// construyen las pantallas.
class Rutas {
  Rutas._();

  static const String bienvenida = '/bienvenida';
  static const String registro = '/registro';
  static const String inicio = '/inicio';
  static const String mapa = '/mapa';
  static const String alertas = '/alertas';
  static const String reportes = '/reportes';
  static const String perfil = '/perfil';

  /// Rutas que se ven sin sesión (acceso e incorporación).
  static const Set<String> publicas = {bienvenida, registro};
}

/// Crea el enrutador con la guarda de sesión: sin sesión → [Rutas.bienvenida];
/// con sesión, las rutas de acceso llevan a [Rutas.inicio].
///
/// [haySesion] lo aporta `EstadoSesion` (Firebase Auth).
GoRouter crearEnrutador({required ValueListenable<bool> haySesion}) {
  return GoRouter(
    initialLocation: Rutas.inicio,
    refreshListenable: haySesion,
    redirect: (context, estado) {
      final esPublica = Rutas.publicas.contains(estado.matchedLocation);
      if (!haySesion.value) return esPublica ? null : Rutas.bienvenida;
      if (esPublica) return Rutas.inicio;
      return null;
    },
    routes: [
      // TODO(HU-02): reemplazar por splash + onboarding + inicio de sesión.
      GoRoute(
        path: Rutas.bienvenida,
        builder: (context, estado) => PantallaEnConstruccion(
          titulo: Textos.nombreApp,
          conBarra: false,
          accion: BotonPrincipal(
            texto: Textos.crearCuenta,
            alPresionar: () => context.push(Rutas.registro),
          ),
        ),
      ),
      GoRoute(
        path: Rutas.registro,
        builder: (context, estado) => ChangeNotifierProvider(
          create: (context) => RegistroVm(context.read<CuentaServicio>()),
          child: const RegistroPantalla(),
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
          _rama(Rutas.perfil, Textos.navPerfil),
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
