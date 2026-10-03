import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'config/tema/tema_app.dart';
import 'config/textos.dart';

/// Raíz de la app: tema claro por defecto y oscuro según la preferencia del
/// usuario (se conecta a `usuarios.temaOscuro` en la Etapa 6).
class AgroClimaApp extends StatelessWidget {
  const AgroClimaApp({
    super.key,
    required this.enrutador,
    this.modoTema = ThemeMode.light,
  });

  final GoRouter enrutador;
  final ThemeMode modoTema;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Textos.nombreApp,
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      darkTheme: TemaApp.oscuro,
      themeMode: modoTema,
      locale: const Locale('es', 'GT'),
      supportedLocales: const [Locale('es', 'GT'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: enrutador,
      // Íconos oscuros en la barra de estado sobre fondo claro; las pantallas
      // con barra superior verde (AppBar) y el splash ponen los suyos.
      builder: (context, hijo) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: modoTema == ThemeMode.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: hijo!,
      ),
    );
  }
}
