import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../componentes/grupo_opciones.dart';
import '../../config/rutas.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';

/// Pantalla 30 · Ayuda y glosario: preguntas comunes (una abierta a la vez,
/// se toca para ver la respuesta) y palabras del clima explicadas en
/// sencillo. Al final, "Acerca de la app". No lee datos: funciona sin señal.
class AyudaPantalla extends StatelessWidget {
  const AyudaPantalla({super.key});

  /// Palabra, explicación, ícono y si va en ámbar (calor) o azul (agua, frío).
  static const List<(String, String, IconData, bool)> glosario = [
    (Textos.helada, Textos.heladaDetalle, Symbols.ac_unit, false),
    (
      Textos.canicula,
      Textos.caniculaDetalle,
      Symbols.local_fire_department,
      true,
    ),
    (Textos.humedad, Textos.humedadDetalle, Symbols.humidity_percentage, false),
    (Textos.milimetro, Textos.milimetroDetalle, Symbols.water_drop, false),
    (
      Textos.diasSinLluviaGlosario,
      Textos.diasSinLluviaDetalle,
      Symbols.wb_sunny,
      true,
    ),
    (
      Textos.vientoFuerteGlosario,
      Textos.vientoFuerteDetalle,
      Symbols.air,
      false,
    ),
    (
      Textos.pronosticoGlosario,
      Textos.pronosticoDetalle,
      Symbols.partly_cloudy_day,
      false,
    ),
    (Textos.coloresAviso, Textos.coloresAvisoDetalle, Symbols.traffic, true),
  ];

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(Textos.ayuda)),
      body: ListView(
        padding: const EdgeInsets.all(Medidas.margenPantalla),
        children: [
          const _Titulo(Textos.preguntasComunes),
          const _Preguntas(),
          const _Titulo(Textos.queQuiereDecir),
          // De dos en dos; las dos tarjetas de cada fila con la misma altura.
          for (var i = 0; i < glosario.length; i += 2) ...[
            if (i > 0) const SizedBox(height: Medidas.separacionTarjetas),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _Palabra.de(glosario[i])),
                  const SizedBox(width: Medidas.separacionTarjetas),
                  Expanded(
                    child: i + 1 < glosario.length
                        ? _Palabra.de(glosario[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Medidas.espacioM),
          GrupoOpciones(
            filas: [
              FilaOpcion(
                icono: Symbols.info,
                texto: Textos.acercaDeLaApp,
                color: esquema.onSurface,
                alTocar: () => context.push(Rutas.acercaDe),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Medidas.espacioS, bottom: 12),
    child: Semantics(
      header: true,
      child: Text(
        texto,
        style: Tipografia.titulo.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
  );
}

/// Preguntas en una tarjeta; tocar una la abre y cierra la anterior.
class _Preguntas extends StatefulWidget {
  const _Preguntas();

  @override
  State<_Preguntas> createState() => _PreguntasState();
}

class _PreguntasState extends State<_Preguntas> {
  int? _abierta = 0;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return GrupoOpciones(
      filas: [
        for (final (i, (pregunta, respuesta)) in Textos.preguntas.indexed)
          Semantics(
            button: true,
            expanded: _abierta == i,
            child: InkWell(
              onTap: () => setState(() => _abierta = _abierta == i ? null : i),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pregunta,
                            style: Tipografia.subtitulo.copyWith(
                              color: esquema.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          _abierta == i
                              ? Symbols.keyboard_arrow_up
                              : Symbols.keyboard_arrow_down,
                          color: _abierta == i
                              ? esquema.primary
                              : esquema.onSurfaceVariant,
                        ),
                      ],
                    ),
                    if (_abierta == i) ...[
                      const SizedBox(height: 10),
                      Text(
                        respuesta,
                        style: Tipografia.cuerpoGrande.copyWith(
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Palabra extends StatelessWidget {
  const _Palabra({
    required this.palabra,
    required this.detalle,
    required this.icono,
    required this.calido,
  });

  factory _Palabra.de((String, String, IconData, bool) entrada) => _Palabra(
    palabra: entrada.$1,
    detalle: entrada.$2,
    icono: entrada.$3,
    calido: entrada.$4,
  );

  final String palabra;
  final String detalle;
  final IconData icono;
  final bool calido;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final claro = Theme.of(context).brightness == Brightness.light;
    final color = calido
        ? (claro ? Colores.precaucionIcono : Colores.solTemaOscuro)
        : (claro ? Colores.acentoCielo : Colores.acentoCieloTemaOscuro);
    return MergeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: 164),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(
          color: esquema.surface,
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          border: Border.all(color: esquema.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icono, size: 44, color: color),
            const SizedBox(height: 10),
            Text(
              palabra,
              textAlign: TextAlign.center,
              style: Tipografia.subtitulo.copyWith(
                fontWeight: FontWeight.w700,
                color: esquema.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: Tipografia.cuerpo.copyWith(
                color: esquema.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
