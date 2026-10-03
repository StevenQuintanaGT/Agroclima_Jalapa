import 'package:flutter/material.dart';

import 'marco_punteado.dart';

/// Recuadro punteado con un ícono grande: ocupa el lugar de las ilustraciones
/// del diseño mientras llegan las definitivas (handoff: "ILUSTRACIÓN").
class IlustracionProvisional extends StatelessWidget {
  const IlustracionProvisional({
    super.key,
    required this.icono,
    required this.colorIcono,
    required this.colorFondo,
    required this.colorBorde,
    this.ancho = 220,
    this.alto = 200,
  });

  final IconData icono;
  final Color colorIcono;
  final Color colorFondo;
  final Color colorBorde;
  final double ancho;
  final double alto;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: MarcoPunteado(
        colorBorde: colorBorde,
        colorFondo: colorFondo,
        radio: 20,
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: ancho,
          height: alto,
          child: Icon(icono, size: 68, color: colorIcono),
        ),
      ),
    );
  }
}
