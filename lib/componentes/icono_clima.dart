import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../config/tema/colores.dart';

/// Ícono y color para el código de condición del proveedor del clima.
class IconoClima extends StatelessWidget {
  const IconoClima({
    super.key,
    required this.codigo,
    required this.esDeDia,
    this.tamano = 64,
  });

  final int codigo;
  final bool esDeDia;
  final double tamano;

  static IconData iconoDe(int codigo, {required bool esDeDia}) =>
      switch (codigo) {
        >= 200 && < 300 => Symbols.thunderstorm,
        >= 300 && < 400 => Symbols.grain,
        >= 500 && < 600 => Symbols.rainy,
        >= 600 && < 700 => Symbols.weather_snowy,
        >= 700 && < 800 => Symbols.foggy,
        800 => esDeDia ? Symbols.sunny : Symbols.clear_night,
        801 || 802 =>
          esDeDia ? Symbols.partly_cloudy_day : Symbols.partly_cloudy_night,
        _ => Symbols.cloud,
      };

  static Color colorDe(
    int codigo, {
    required bool esDeDia,
    required bool claro,
  }) {
    final soleado = codigo == 800 || codigo == 801 || codigo == 802;
    if (soleado && esDeDia) return claro ? Colores.sol : Colores.solTemaOscuro;
    if (codigo >= 200 && codigo < 600) {
      return claro ? Colores.acentoCielo : Colores.acentoCieloTemaOscuro;
    }
    return claro ? Colores.textoTenue : Colores.textoTenueOscuro;
  }

  @override
  Widget build(BuildContext context) {
    final claro = Theme.of(context).brightness == Brightness.light;
    return ExcludeSemantics(
      child: Icon(
        iconoDe(codigo, esDeDia: esDeDia),
        size: tamano,
        fill: 1,
        color: colorDe(codigo, esDeDia: esDeDia, claro: claro),
      ),
    );
  }
}
