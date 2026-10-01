import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../componentes/logo_app.dart';
import '../../config/rutas.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';

/// Pantalla 01 · Splash. Muestra la marca un momento y pasa a Inicio; la
/// guarda de sesión decide si en realidad va a bienvenida o a entrar.
class SplashPantalla extends StatefulWidget {
  const SplashPantalla({
    super.key,
    this.espera = const Duration(milliseconds: 1200),
  });

  final Duration espera;

  @override
  State<SplashPantalla> createState() => _SplashPantallaState();
}

class _SplashPantallaState extends State<SplashPantalla> {
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer(widget.espera, () {
      if (mounted) context.go(Rutas.inicio);
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blanco = Colors.white;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colores.primarioOscuro,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LogoApp(tamano: 120, claro: true),
                const SizedBox(height: 20),
                Text(
                  Textos.marca,
                  style: Tipografia.datoGrande.copyWith(color: blanco),
                ),
                Text(
                  Textos.marcaLugar,
                  style: Tipografia.titulo.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: blanco.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  Textos.lema,
                  textAlign: TextAlign.center,
                  style: Tipografia.cuerpo.copyWith(
                    color: blanco.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor: blanco.withValues(alpha: 0.28),
                      color: Colores.primarioTemaOscuro,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
