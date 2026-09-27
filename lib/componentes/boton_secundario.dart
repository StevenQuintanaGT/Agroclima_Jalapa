import 'package:flutter/material.dart';

import '../config/tema/colores.dart';

/// Botón secundario: 56 dp, fondo blanco y borde de 2 dp. Neutro por defecto
/// ("Ahora no", "Ver datos guardados"); con [destacado] el borde y el texto
/// van en verde ("Intentar de nuevo" en la pantalla sin conexión).
class BotonSecundario extends StatelessWidget {
  const BotonSecundario({
    super.key,
    required this.texto,
    required this.alPresionar,
    this.icono,
    this.destacado = false,
  });

  final String texto;
  final VoidCallback? alPresionar;
  final IconData? icono;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final esClaro = Theme.of(context).brightness == Brightness.light;
    final estilo = destacado
        ? OutlinedButton.styleFrom(
            foregroundColor: esClaro ? Colores.primarioOscuro : esquema.primary,
            side: BorderSide(color: esquema.primary, width: 2),
          )
        : null;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: alPresionar,
        style: estilo,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icono != null) ...[
              Icon(icono, size: 26),
              const SizedBox(width: 10),
            ],
            Flexible(child: Text(texto, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}
