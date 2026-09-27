import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../config/tema/tipografia.dart';
import '../config/textos.dart';

/// Aviso fijo en el panel y el detalle de alerta: la información es de apoyo,
/// no un aviso oficial (RN-07, RC-03).
class AvisoApoyo extends StatelessWidget {
  const AvisoApoyo({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Symbols.info, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            Textos.avisoApoyo,
            style: Tipografia.cuerpoChico.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
