import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../config/tema/medidas.dart';
import '../config/tema/tipografia.dart';

/// Tarjeta con filas separadas por una línea (Perfil, Ajustes; pantallas 28
/// y 29).
class GrupoOpciones extends StatelessWidget {
  const GrupoOpciones({super.key, required this.filas});

  final List<Widget> filas;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Material(
      color: esquema.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        side: BorderSide(color: esquema.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < filas.length; i++) ...[
            if (i > 0) Divider(height: 1, color: esquema.outlineVariant),
            filas[i],
          ],
        ],
      ),
    );
  }
}

/// Fila con ícono y palabra. Con [alTocar] y sin [alFinal] lleva la flecha
/// ">" de "abre otra pantalla", salvo que [conFlecha] diga otra cosa.
class FilaOpcion extends StatelessWidget {
  const FilaOpcion({
    super.key,
    required this.icono,
    required this.texto,
    this.detalle,
    this.alFinal,
    this.alTocar,
    this.color,
    this.conFlecha,
  });

  final IconData icono;
  final String texto;
  final String? detalle;
  final Widget? alFinal;
  final VoidCallback? alTocar;

  /// Ícono y texto en otro color (p. ej. rojo para "Eliminar mi cuenta").
  final Color? color;
  final bool? conFlecha;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final colorTexto = color ?? esquema.onSurface;
    final colorIcono = color ?? esquema.primary;
    return InkWell(
      onTap: alTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(icono, size: 30, color: colorIcono),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      texto,
                      style: Tipografia.subtitulo.copyWith(color: colorTexto),
                    ),
                    if (detalle != null)
                      Text(
                        detalle!,
                        style: Tipografia.cuerpo.copyWith(
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (alFinal != null) ...[
                const SizedBox(width: 12),
                alFinal!,
              ] else if (conFlecha ?? alTocar != null)
                Icon(Symbols.chevron_right, color: esquema.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Título de un grupo en mayúsculas grises ("CÓMO SE MUESTRAN LOS DATOS").
class TituloGrupo extends StatelessWidget {
  const TituloGrupo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, Medidas.espacioM, 4, 12),
    child: Semantics(
      header: true,
      child: Text(
        texto.toUpperCase(),
        style: Tipografia.etiqueta.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    ),
  );
}
