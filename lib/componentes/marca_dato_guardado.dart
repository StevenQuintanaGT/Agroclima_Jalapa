import 'package:flutter/material.dart';

import '../config/tema/colores.dart';
import '../config/tema/tipografia.dart';
import '../config/textos.dart';
import 'marco_punteado.dart';

/// Recuadro punteado con la fecha del dato guardado (pantalla 32): nunca se
/// confunde lo guardado con lo actual (RNF-08).
class MarcaDatoGuardado extends StatelessWidget {
  const MarcaDatoGuardado({super.key, required this.fechaHora});

  /// Ya formateada para el productor, p. ej. "12 de agosto, 6:00 a.m.".
  final String fechaHora;

  @override
  Widget build(BuildContext context) {
    return MarcoPunteado(
      colorBorde: Colores.bordeFuerte,
      colorFondo: Colores.fondoDatoGuardado,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          Textos.datosDel(fechaHora),
          textAlign: TextAlign.center,
          style: Tipografia.cuerpo.copyWith(
            fontWeight: FontWeight.w500,
            color: Colores.textoSecundario,
          ),
        ),
      ),
    );
  }
}
