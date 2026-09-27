import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../config/tema/colores_semaforo.dart';
import '../config/textos.dart';
import '../config/tema/tipografia.dart';
import '../modelos/enums.dart';

/// Nivel de riesgo: SIEMPRE color + ícono + palabra juntos (Tabla 72), para
/// que se entienda sin distinguir colores y de reojo bajo el sol.
class ChipSemaforo extends StatelessWidget {
  const ChipSemaforo({super.key, required this.nivel});

  final NivelSeveridad nivel;

  static IconData iconoDe(NivelSeveridad nivel) => switch (nivel) {
    NivelSeveridad.informativa => Symbols.check_circle,
    NivelSeveridad.preventiva => Symbols.warning,
    NivelSeveridad.critica => Symbols.error,
  };

  @override
  Widget build(BuildContext context) {
    final tono = ColoresSemaforo.of(context).de(nivel);
    final palabra = Textos.palabraNivel(nivel);
    return Semantics(
      label: palabra,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: tono.fondo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tono.borde, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconoDe(nivel), size: 16, color: tono.icono),
            const SizedBox(width: 4),
            Text(
              palabra,
              style: Tipografia.etiquetaChica.copyWith(color: tono.texto),
            ),
          ],
        ),
      ),
    );
  }
}
