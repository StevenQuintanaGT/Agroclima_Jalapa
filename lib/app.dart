import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/textos.dart';

/// Raíz de la app. El tema, las rutas (go_router) y la barra inferior se
/// agregan en la tarea "Tema visual, componentes y navegación" del plan.
class AgroClimaApp extends StatelessWidget {
  const AgroClimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Textos.nombreApp,
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'GT'),
      supportedLocales: const [Locale('es', 'GT'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(Textos.marca, style: TextStyle(fontSize: 40)),
                Text(Textos.marcaLugar, style: TextStyle(fontSize: 22)),
                SizedBox(height: 16),
                Text(Textos.lema, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
