import 'package:flutter/material.dart';

import '../config/tema/colores.dart';
import '../config/tema/medidas.dart';
import '../config/tema/tipografia.dart';
import 'boton_secundario.dart';

/// Diálogo para confirmar algo que no se puede deshacer (pantalla 15). Los
/// botones dicen la consecuencia ("Sí, borrar" / "No, quedarme"), nunca
/// "Aceptar / Cancelar".
class DialogoConfirmar extends StatelessWidget {
  const DialogoConfirmar({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.textoConfirmar,
    required this.textoCancelar,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final String textoConfirmar;
  final String textoCancelar;

  /// Muestra el diálogo. Devuelve `true` solo si el productor confirmó.
  static Future<bool> mostrar(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String detalle,
    required String textoConfirmar,
    required String textoCancelar,
  }) async {
    final confirmo = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => DialogoConfirmar(
        icono: icono,
        titulo: titulo,
        detalle: detalle,
        textoConfirmar: textoConfirmar,
        textoCancelar: textoCancelar,
      ),
    );
    return confirmo ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(Medidas.espacioM),
      backgroundColor: esquema.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: esquema.error),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Tipografia.titulo.copyWith(color: esquema.onSurface),
            ),
            const SizedBox(height: Medidas.espacioXs),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: Tipografia.cuerpo.copyWith(
                fontSize: 17,
                height: 1.45,
                color: esquema.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: Medidas.alturaBotonSecundario,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colores.peligroBorde,
                  foregroundColor: Colors.white,
                  textStyle: Tipografia.boton.copyWith(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Medidas.radioBoton),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(textoConfirmar),
              ),
            ),
            const SizedBox(height: 10),
            BotonSecundario(
              texto: textoCancelar,
              alPresionar: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
