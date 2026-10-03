import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/aviso_error.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import 'mapa_parcela.dart';
import 'registro_parcela_vm.dart';

/// Paso 4 (pantalla 13): revisión. Cada dato tiene su "Cambiar", que lleva a
/// su paso y vuelve aquí sin rehacer el asistente.
class PasoRevision extends StatelessWidget {
  const PasoRevision({super.key, required this.constructorMapa});

  final ConstructorMapa constructorMapa;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistroParcelaVm>();
    final cultivo = vm.sinSembrar || vm.cultivo == null
        ? Textos.sinSembrar
        : '${Textos.cultivo(vm.cultivo!)} · ${Textos.etapa(vm.etapa!)}';
    final tamano = [
      if (vm.area != null)
        '${_numero(vm.area!)} ${vm.unidadArea == 'manzana' ? Textos.manzanas : Textos.hectareasCorto}',
      if (vm.altitud != null) Textos.msnm(vm.altitud!),
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        if (vm.errorGeneral != null) ...[
          AvisoError(texto: vm.errorGeneral!),
          const SizedBox(height: Medidas.espacioS),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          child: SizedBox(
            height: 130,
            child: IgnorePointer(
              child: constructorMapa(
                latitud: vm.latitud,
                longitud: vm.longitud,
                puntoPuesto: true,
                alMoverPin: (_, _) {},
              ),
            ),
          ),
        ),
        const SizedBox(height: Medidas.espacioS),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              _Fila(
                icono: Symbols.agriculture,
                etiqueta: Textos.etiquetaNombre,
                valor: vm.nombre.trim(),
                alCambiar: () => vm.cambiarPaso(1),
              ),
              const Divider(),
              _Fila(
                icono: Symbols.location_city,
                etiqueta: Textos.etiquetaMunicipio,
                valor: vm.municipio == null
                    ? Textos.sinDato
                    : Textos.municipio(vm.municipio!),
                alCambiar: () => vm.cambiarPaso(1),
              ),
              const Divider(),
              _Fila(
                icono: Symbols.grass,
                etiqueta: Textos.etiquetaCultivo,
                valor: cultivo,
                alCambiar: () => vm.cambiarPaso(2),
              ),
              const Divider(),
              _Fila(
                icono: Symbols.pin_drop,
                etiqueta: Textos.coordenadas,
                valor: vm.coordenadasTexto,
                alCambiar: () => vm.cambiarPaso(3),
              ),
              const Divider(),
              _Fila(
                icono: Symbols.straighten,
                etiqueta: Textos.etiquetaTamanoAltura,
                valor: tamano.isEmpty ? Textos.sinDato : tamano,
                alCambiar: () => vm.cambiarPaso(3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _numero(double valor) => valor == valor.roundToDouble()
      ? valor.toStringAsFixed(0)
      : valor.toString();
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.alCambiar,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final VoidCallback alCambiar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final esClaro = Theme.of(context).brightness == Brightness.light;
    final verde = esClaro ? Colores.primarioOscuro : Colores.primarioTemaOscuro;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          Icon(icono, size: 28, color: verde),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: Tipografia.cuerpoChico.copyWith(
                    color: Colores.textoTenue,
                  ),
                ),
                Text(
                  valor,
                  style: Tipografia.cuerpoGrande.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: esquema.onSurface,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: alCambiar,
            child: Text(
              Textos.cambiar,
              style: Tipografia.cuerpo.copyWith(
                fontWeight: FontWeight.w700,
                color: verde,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
