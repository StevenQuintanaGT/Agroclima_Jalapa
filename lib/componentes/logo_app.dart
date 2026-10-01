import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../config/tema/colores.dart';

/// Logotipo provisional del diseño: ícono de lluvia sobre cuadro redondeado.
class LogoApp extends StatelessWidget {
  const LogoApp({super.key, this.tamano = 56, this.claro = false});

  final double tamano;

  /// `true` = cuadro blanco con ícono verde (splash); `false` = al revés.
  final bool claro;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(
          color: claro ? Colors.white : Colores.primarioOscuro,
          borderRadius: BorderRadius.circular(tamano * 0.3),
        ),
        child: Icon(
          Symbols.rainy,
          size: tamano * 0.6,
          color: claro ? Colores.primarioOscuro : Colors.white,
        ),
      ),
    );
  }
}
