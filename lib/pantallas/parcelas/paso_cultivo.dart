import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/chip_seleccion.dart';
import '../../componentes/tarjeta_opcion.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/enums.dart';
import 'registro_parcela_vm.dart';

/// Paso 2 (pantalla 11): cultivo (4 tarjetas, D-01) y "¿Cómo va el cultivo?"
/// (5 etapas, D-02). Cultivo y etapa deciden los umbrales de alerta (RN-05).
class PasoCultivo extends StatelessWidget {
  const PasoCultivo({super.key});

  static IconData iconoDe(Cultivo cultivo) => switch (cultivo) {
    Cultivo.maiz => Symbols.grass,
    Cultivo.frijol => Symbols.eco,
    Cultivo.cafe => Symbols.coffee,
    Cultivo.hortalizas => Symbols.nutrition,
  };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistroParcelaVm>();
    final esquema = Theme.of(context).colorScheme;
    final estiloError = Tipografia.cuerpoChico.copyWith(color: esquema.error);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text(
          Textos.pregCultivo,
          style: Tipografia.titulo.copyWith(color: esquema.onSurface),
        ),
        const SizedBox(height: Medidas.espacioS),
        // Filas que crecen con el texto (letra grande del teléfono), no una
        // cuadrícula de alto fijo.
        for (var i = 0; i < Cultivo.values.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final cultivo in Cultivo.values.skip(i).take(2)) ...[
                  if (cultivo != Cultivo.values[i]) const SizedBox(width: 12),
                  Expanded(
                    child: TarjetaOpcion(
                      icono: iconoDe(cultivo),
                      texto: Textos.cultivo(cultivo),
                      elegida: vm.cultivo == cultivo,
                      alTocar: () => vm.elegirCultivo(cultivo),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        ChipSeleccion(
          texto: Textos.sinSembrar,
          elegido: vm.sinSembrar,
          alTocar: vm.elegirSinSembrar,
          radio: Medidas.radioTarjeta,
        ),
        if (vm.sinSembrar) ...[
          const SizedBox(height: Medidas.espacioXs),
          Text(
            Textos.ayudaSinSembrar,
            style: Tipografia.cuerpo.copyWith(color: esquema.onSurfaceVariant),
          ),
        ],
        if (vm.faltaCultivo) ...[
          const SizedBox(height: Medidas.espacioXs),
          Text(Textos.errorElijaCultivo, style: estiloError),
        ],
        if (vm.cultivo != null) ...[
          const SizedBox(height: Medidas.espacioL),
          Text(
            Textos.pregEtapa,
            style: Tipografia.titulo.copyWith(color: esquema.onSurface),
          ),
          const SizedBox(height: Medidas.espacioS),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final etapa in Etapa.values)
                ChipSeleccion(
                  texto: Textos.etapa(etapa),
                  elegido: vm.etapa == etapa,
                  alTocar: () => vm.elegirEtapa(etapa),
                ),
            ],
          ),
          if (vm.faltaEtapa) ...[
            const SizedBox(height: Medidas.espacioXs),
            Text(Textos.errorElijaEtapa, style: estiloError),
          ],
        ],
      ],
    );
  }
}
