import 'package:flutter/material.dart';

import '../config/tema/medidas.dart';
import '../config/tema/tipografia.dart';

/// Botón de opción en forma de píldora (municipios, etapas, unidades): todas
/// las opciones visibles a la vez, nunca un desplegable (pantalla 10).
/// 48 dp de alto; la elegida en verde con letra blanca.
class ChipSeleccion extends StatelessWidget {
  const ChipSeleccion({
    super.key,
    required this.texto,
    required this.elegido,
    required this.alTocar,
    this.radio = Medidas.radioPildora,
  });

  final String texto;
  final bool elegido;
  final VoidCallback alTocar;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: elegido,
      label: texto,
      excludeSemantics: true,
      child: Material(
        color: elegido ? esquema.primary : esquema.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radio),
          side: elegido
              ? BorderSide.none
              : BorderSide(color: esquema.outline, width: 1.5),
        ),
        child: InkWell(
          onTap: alTocar,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radio),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Medidas.minimoTactil),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                texto,
                textAlign: TextAlign.center,
                style: Tipografia.cuerpoGrande.copyWith(
                  height: 1.2,
                  fontWeight: elegido ? FontWeight.w700 : FontWeight.w500,
                  color: elegido ? esquema.onPrimary : esquema.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
