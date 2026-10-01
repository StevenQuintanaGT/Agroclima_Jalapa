import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../config/tema/colores_semaforo.dart';
import '../config/tema/medidas.dart';
import '../config/tema/tipografia.dart';
import '../modelos/enums.dart';

/// Error general de un formulario (sin señal, correo ya usado…) en lenguaje
/// llano, con ícono y color de PELIGRO; nunca solo color.
class AvisoError extends StatelessWidget {
  const AvisoError({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tono = ColoresSemaforo.of(context).de(NivelSeveridad.critica);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tono.fondo,
          borderRadius: BorderRadius.circular(Medidas.radioCampo),
          border: Border.all(color: tono.borde, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Symbols.error, size: 24, color: tono.icono),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                texto,
                style: Tipografia.cuerpo.copyWith(color: tono.texto),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
