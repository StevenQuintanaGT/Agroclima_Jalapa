import 'package:flutter/material.dart';

import '../config/tema/colores.dart';

/// Barra de progreso del asistente (pantallas 10–13): un segmento por paso,
/// los completados en verde claro (RNF-12).
class BarraProgresoPasos extends StatelessWidget {
  const BarraProgresoPasos({
    super.key,
    required this.actual,
    required this.total,
  });

  final int actual;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Paso $actual de $total',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 1; i <= total; i++) ...[
            if (i > 1) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: i <= actual
                      ? Colores.primarioTemaOscuro
                      : Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
