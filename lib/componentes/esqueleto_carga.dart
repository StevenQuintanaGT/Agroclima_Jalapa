import 'package:flutter/material.dart';

import '../config/tema/colores.dart';

/// Bloque gris que anticipa la forma del contenido mientras carga
/// (pantalla 33). Sin animación: los teléfonos de gama baja la sufren.
class EsqueletoCarga extends StatelessWidget {
  const EsqueletoCarga({
    super.key,
    this.alto = 16,
    this.ancho = double.infinity,
    this.radio = 12,
  });

  final double alto;
  final double ancho;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final esClaro = Theme.of(context).brightness == Brightness.light;
    return ExcludeSemantics(
      child: Container(
        width: ancho,
        height: alto,
        decoration: BoxDecoration(
          color: esClaro ? Colores.esqueleto : Colores.bordeOscuro,
          borderRadius: BorderRadius.circular(radio),
        ),
      ),
    );
  }
}
