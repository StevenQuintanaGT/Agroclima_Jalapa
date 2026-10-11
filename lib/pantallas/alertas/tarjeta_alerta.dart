import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../componentes/chip_semaforo.dart';
import '../../componentes/icono_riesgo.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/colores_semaforo.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/alerta.dart';
import '../../modelos/enums.dart';

/// Tarjeta del centro de alertas (pantalla 21): franja lateral del color del
/// nivel (se ve de reojo), ícono del riesgo, semáforo, parcela y cuándo. El
/// punto rojo marca las que no se han abierto.
class TarjetaAlerta extends StatelessWidget {
  const TarjetaAlerta({
    super.key,
    required this.alerta,
    required this.ahora,
    required this.alTocar,
  });

  final Alerta alerta;
  final DateTime ahora;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final tono = ColoresSemaforo.of(context).de(alerta.nivel);
    // NORMAL no apura: su hora va en gris, como en el diseño.
    final colorCuando = alerta.nivel == NivelSeveridad.informativa
        ? esquema.onSurfaceVariant
        : tono.icono;
    return Semantics(
      button: true,
      label: Textos.lecturaTarjetaAlerta(alerta, ahora),
      excludeSemantics: true,
      child: Material(
        color: esquema.surface,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
              border: Border.all(color: esquema.outlineVariant),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 10, color: tono.borde),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            IconoRiesgo.de(alerta),
                            size: 40,
                            color: tono.icono,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ChipSemaforo(nivel: alerta.nivel),
                                const SizedBox(height: 8),
                                Text(
                                  Textos.tituloAlerta(alerta),
                                  style: Tipografia.titulo.copyWith(
                                    color: esquema.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Textos.parcelaYCultivo(
                                    alerta.parcelaNombre,
                                    alerta.cultivo,
                                  ),
                                  style: Tipografia.cuerpoGrande.copyWith(
                                    color: esquema.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Symbols.schedule,
                                        size: 22,
                                        color: colorCuando,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        Textos.cuandoAlerta(alerta, ahora),
                                        style: Tipografia.cuerpoGrande.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: colorCuando,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Historial (HU-14): si el productor atendió el aviso.
                                if (alerta.atendida) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Symbols.task_alt,
                                        size: 22,
                                        color: esquema.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          Textos.yaTomoMedidas,
                                          style: Tipografia.cuerpo.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: esquema.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!alerta.leida)
                            Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.only(top: 4, left: 4),
                              decoration: const BoxDecoration(
                                color: Colores.peligroBorde,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
