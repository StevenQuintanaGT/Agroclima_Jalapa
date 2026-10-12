import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../componentes/logo_app.dart';
import '../../config/constantes.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';

/// Pantalla 31 · Acerca de: de dónde salen los datos (OpenWeather por
/// cuadro, no medición en la parcela; mapas de Esri y límites de
/// geoBoundaries, D-37), que no es aviso oficial (RN-07), quién la hizo y
/// los términos de uso y privacidad.
class AcercaPantalla extends StatelessWidget {
  const AcercaPantalla({super.key});

  void _mostrarTerminos(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (contexto) {
      final esquema = Theme.of(contexto).colorScheme;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                Textos.terminosYPrivacidad,
                style: Tipografia.titular.copyWith(color: esquema.onSurface),
              ),
              const SizedBox(height: Medidas.espacioS),
              for (final punto in Textos.terminos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Symbols.check_circle,
                          size: 22,
                          color: esquema.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          punto,
                          style: Tipografia.cuerpoGrande.copyWith(
                            color: esquema.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: Medidas.espacioXs),
              FilledButton(
                onPressed: () => Navigator.of(contexto).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    Medidas.alturaBotonSecundario,
                  ),
                ),
                child: const Text(Textos.entendido),
              ),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(Textos.acercaDe)),
      body: ListView(
        padding: const EdgeInsets.all(Medidas.margenPantalla),
        children: [
          const SizedBox(height: Medidas.espacioM),
          const Center(child: LogoApp(tamano: 112)),
          const SizedBox(height: Medidas.espacioM),
          Text(
            Textos.nombreApp,
            textAlign: TextAlign.center,
            style: Tipografia.datoGrande.copyWith(color: esquema.onSurface),
          ),
          Text(
            Textos.version(Constantes.versionApp),
            textAlign: TextAlign.center,
            style: Tipografia.cuerpoGrande.copyWith(
              color: esquema.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Medidas.espacioM),
          const _Tarjeta(
            titulo: Textos.deDondeSalen,
            detalle: Textos.deDondeSalenDetalle,
            pie: Textos.fuentesMapas,
          ),
          const SizedBox(height: Medidas.separacionTarjetas),
          const _Tarjeta(
            titulo: Textos.noEsOficial,
            detalle: Textos.noEsOficialDetalle,
          ),
          const SizedBox(height: Medidas.separacionTarjetas),
          const _Tarjeta(
            titulo: Textos.quienLaHizo,
            detalle: Textos.quienLaHizoDetalle,
          ),
          const SizedBox(height: Medidas.espacioS),
          Center(
            child: TextButton(
              onPressed: () => _mostrarTerminos(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, Medidas.minimoTactil),
              ),
              child: Text(
                Textos.terminosYPrivacidad,
                style: Tipografia.subtitulo.copyWith(
                  fontWeight: FontWeight.w700,
                  color: esquema.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.titulo, required this.detalle, this.pie});

  final String titulo;
  final String detalle;
  final String? pie;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esquema.surface,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        border: Border.all(color: esquema.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              titulo,
              style: Tipografia.subtitulo.copyWith(
                fontWeight: FontWeight.w700,
                color: esquema.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detalle,
            style: Tipografia.cuerpoGrande.copyWith(
              color: esquema.onSurfaceVariant,
            ),
          ),
          if (pie != null) ...[
            const SizedBox(height: 8),
            Text(
              pie!,
              style: Tipografia.cuerpo.copyWith(
                color: esquema.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
