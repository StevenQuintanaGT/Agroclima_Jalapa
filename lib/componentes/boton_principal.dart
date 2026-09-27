import 'package:flutter/material.dart';

/// Botón principal: 60 dp de alto, ancho completo, verde (handoff de diseño).
/// Con [cargando] muestra un indicador y [textoCargando] (p. ej. "Entrando…")
/// y no responde a toques.
class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.alPresionar,
    this.icono,
    this.cargando = false,
    this.textoCargando,
  });

  final String texto;
  final VoidCallback? alPresionar;
  final IconData? icono;
  final bool cargando;
  final String? textoCargando;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final Widget contenido;
    if (cargando) {
      contenido = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: esquema.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(textoCargando ?? texto)),
        ],
      );
    } else if (icono != null) {
      contenido = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 26),
          const SizedBox(width: 10),
          Flexible(child: Text(texto, textAlign: TextAlign.center)),
        ],
      );
    } else {
      contenido = Text(texto, textAlign: TextAlign.center);
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: cargando ? null : alPresionar,
        style: cargando
            ? FilledButton.styleFrom(
                disabledBackgroundColor: esquema.primary,
                disabledForegroundColor: esquema.onPrimary,
              )
            : null,
        child: contenido,
      ),
    );
  }
}
