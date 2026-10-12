import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'config/tema/tema_app.dart';
import 'config/textos.dart';
import 'servicios/perfil_servicio.dart';
import 'utilidades/unidades.dart';

/// Raíz de la app: tema claro por defecto y oscuro según "Pantalla oscura";
/// temperatura y terreno en la unidad elegida en Ajustes (pantalla 29, D-55).
class AgroClimaApp extends StatelessWidget {
  const AgroClimaApp({
    super.key,
    required this.enrutador,
    this.perfil,
    this.modoTema = ThemeMode.light,
  });

  final GoRouter enrutador;

  /// Ajustes del productor; sin él (pruebas), tema [modoTema] y métrico.
  final PerfilServicio? perfil;
  final ThemeMode modoTema;

  @override
  Widget build(BuildContext context) {
    final perfil = this.perfil;
    if (perfil == null) return _app(modoTema);
    return ListenableBuilder(
      listenable: perfil,
      builder: (context, _) {
        Unidades.enFahrenheit = perfil.fahrenheit;
        Unidades.enHectareas = perfil.hectareas;
        return _app(perfil.temaOscuro ? ThemeMode.dark : ThemeMode.light);
      },
    );
  }

  Widget _app(ThemeMode modo) => MaterialApp.router(
    title: Textos.nombreApp,
    debugShowCheckedModeBanner: false,
    theme: TemaApp.claro,
    darkTheme: TemaApp.oscuro,
    themeMode: modo,
    locale: const Locale('es', 'GT'),
    supportedLocales: const [Locale('es', 'GT'), Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: enrutador,
    // Íconos oscuros en la barra de estado sobre fondo claro; las pantallas
    // con barra superior verde (AppBar) y el splash ponen los suyos.
    builder: (context, hijo) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: modo == ThemeMode.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      // Los textos leen la unidad al dibujarse: al cambiarla se vuelve a
      // armar todo. La ruta abierta se conserva (la guarda el enrutador).
      child: KeyedSubtree(
        key: ValueKey((Unidades.enFahrenheit, Unidades.enHectareas)),
        child: hijo!,
      ),
    ),
  );
}
