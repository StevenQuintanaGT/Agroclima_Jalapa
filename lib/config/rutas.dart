import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../pantallas/shell/pantalla_en_construccion.dart';
import '../pantallas/shell/shell_pantalla.dart';
import 'textos.dart';

/// Rutas de la app (docs/DISENO_UI.md §8). Se agregan a medida que se
/// construyen las pantallas.
class Rutas {
  Rutas._();

  static const String bienvenida = '/bienvenida';
  static const String inicio = '/inicio';
  static const String mapa = '/mapa';
  static const String alertas = '/alertas';
  static const String reportes = '/reportes';
  static const String perfil = '/perfil';

  /// Rutas que se ven sin sesión (acceso e incorporación).
  static const Set<String> publicas = {bienvenida};
}

/// Crea el enrutador con la guarda de sesión: sin sesión → [Rutas.bienvenida];
/// con sesión, las rutas de acceso llevan a [Rutas.inicio].
///
/// [haySesion] lo aporta el repositorio de autenticación (HU-02).
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
      GoRoute(
        path: Rutas.bienvenida,
        builder: (context, estado) => const PantallaEnConstruccion(
          titulo: Textos.nombreApp,
          conBarra: false,
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
