import 'package:flutter/material.dart';

import '../config/tema/colores.dart';
import '../config/tema/medidas.dart';
import '../config/tema/tipografia.dart';

/// Tarjeta grande de opción con ícono y palabra (cultivos, pantalla 11).
/// La elegida lleva fondo verde claro y borde verde de 3 dp.
class TarjetaOpcion extends StatelessWidget {
  const TarjetaOpcion({
    super.key,
    required this.icono,
    required this.texto,
    required this.elegida,
    required this.alTocar,
  });

  final IconData icono;
  final String texto;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final esClaro = Theme.of(context).brightness == Brightness.light;
    final colorContenido = elegida
        ? (esClaro ? Colores.primarioOscuro : Colores.primarioTemaOscuro)
        : esquema.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: elegida,
      label: texto,
      excludeSemantics: true,
      child: Material(
        color: elegida
            ? (esClaro ? Colores.contenedorClaro : Colores.contenedorTemaOscuro)
            : esquema.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          side: BorderSide(
            color: elegida ? esquema.primary : esquema.outlineVariant,
            width: elegida ? 3 : 1.5,
          ),
        ),
        child: InkWell(
          onTap: alTocar,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, size: 44, color: colorContenido),
                const SizedBox(height: 10),
                Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: Tipografia.cuerpoGrande.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: colorContenido,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
