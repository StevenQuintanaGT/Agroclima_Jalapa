import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../componentes/campo_texto.dart';
import '../../componentes/chip_seleccion.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/enums.dart';
import 'registro_parcela_vm.dart';

/// Paso 1 (pantalla 10): nombre de la parcela y municipio, con los 7
/// municipios visibles a la vez (nunca un desplegable).
class PasoNombre extends StatelessWidget {
  const PasoNombre({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistroParcelaVm>();
    final esquema = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text(
          Textos.pregNombreParcela,
          style: Tipografia.titulo.copyWith(color: esquema.onSurface),
        ),
        const SizedBox(height: 6),
        CampoTexto(
          etiqueta: Textos.ayudaNombreParcela,
          valorInicial: vm.nombre,
          alCambiar: vm.cambiarNombre,
          error: vm.errorNombre,
          valido: vm.nombre.trim().isNotEmpty && vm.errorNombre == null,
          teclado: TextInputType.text,
          accionTeclado: TextInputAction.done,
        ),
        const SizedBox(height: Medidas.espacioL),
        Text(
          Textos.pregMunicipio,
          style: Tipografia.titulo.copyWith(color: esquema.onSurface),
        ),
        const SizedBox(height: Medidas.espacioS),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final municipio in Municipio.values)
              ChipSeleccion(
                texto: Textos.municipio(municipio),
                elegido: vm.municipio == municipio,
                alTocar: () => vm.elegirMunicipio(municipio),
              ),
          ],
        ),
        if (vm.faltaMunicipio) ...[
          const SizedBox(height: Medidas.espacioXs),
          Text(
            Textos.errorElijaMunicipio,
            style: Tipografia.cuerpoChico.copyWith(color: esquema.error),
          ),
        ],
      ],
    );
  }
}
