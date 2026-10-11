import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/boton_principal.dart';
import '../../componentes/estado_vacio.dart';
import '../../config/rutas.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/parcela.dart';
import 'confirmar_borrado.dart';
import 'detalle_parcela_vm.dart';
import 'mapa_parcela.dart';

/// Pantalla 15 · Detalle de la parcela (HU-06). Cada dato abre su paso del
/// asistente para cambiarlo; al pie, "Editar parcela" y "Borrar parcela".
class DetalleParcelaPantalla extends StatelessWidget {
  const DetalleParcelaPantalla({
    super.key,
    this.constructorMapa = MapaParcela.construir,
  });

  final ConstructorMapa constructorMapa;

  void _editar(BuildContext context, Parcela parcela, [int? paso]) => context
      .push(Rutas.editarParcela(parcela.parcelaId, paso: paso), extra: parcela);

  Future<void> _borrar(
    BuildContext context,
    DetalleParcelaVm vm,
    Parcela parcela,
  ) async {
    final borrada = await confirmarBorrado(
      context,
      nombre: parcela.nombre,
      borrar: vm.borrar,
    );
    if (borrada && context.mounted) {
      context.canPop() ? context.pop() : context.go(Rutas.inicio);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetalleParcelaVm>();
    final parcela = vm.parcela;
    return Scaffold(
      appBar: AppBar(
        title: Text(parcela?.nombre ?? Textos.misParcelas),
        actions: [
          if (parcela != null && !vm.borrada)
            IconButton(
              tooltip: Textos.verDiaPorDia,
              icon: const Icon(Symbols.calendar_month),
              onPressed: () =>
                  context.push(Rutas.historialParcela(parcela.parcelaId)),
            ),
        ],
      ),
      body: SafeArea(
        child: vm.noExiste
            ? const EstadoVacio(
                icono: Symbols.agriculture,
                titulo: Textos.parcelaNoExiste,
                detalle: Textos.vacioParcelasDetalle,
              )
            : parcela == null || vm.borrada
            ? const SizedBox.shrink()
            : _Datos(
                parcela: parcela,
                constructorMapa: constructorMapa,
                alCambiar: (paso) => _editar(context, parcela, paso),
              ),
      ),
      bottomNavigationBar: parcela == null || vm.borrada
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BotonPrincipal(
                      texto: Textos.editarParcela,
                      icono: Symbols.edit,
                      alPresionar: () => _editar(context, parcela),
                    ),
                    const SizedBox(height: Medidas.espacioXs),
                    SizedBox(
                      width: double.infinity,
                      height: Medidas.alturaBotonSecundario,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          textStyle: Tipografia.boton.copyWith(fontSize: 18),
                        ),
                        onPressed: vm.borrando
                            ? null
                            : () => _borrar(context, vm, parcela),
                        icon: const Icon(Symbols.delete, size: 24),
                        label: Text(
                          vm.borrando
                              ? Textos.borrandoParcela
                              : Textos.borrarParcela,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Datos extends StatelessWidget {
  const _Datos({
    required this.parcela,
    required this.constructorMapa,
    required this.alCambiar,
  });

  final Parcela parcela;
  final ConstructorMapa constructorMapa;
  final void Function(int paso) alCambiar;

  @override
  Widget build(BuildContext context) {
    final cultivo = parcela.cultivo == null
        ? Textos.sinSembrar
        : [
            Textos.cultivo(parcela.cultivo!),
            if (parcela.etapa != null) Textos.etapa(parcela.etapa!),
          ].join(' · ');
    final area = parcela.area;
    final tamano = [
      if (area != null)
        '${area == area.roundToDouble() ? area.toInt() : area} '
            '${parcela.unidadArea == 'manzana' ? Textos.manzanas : Textos.hectareasCorto}',
      if (parcela.altitud != null) Textos.msnm(parcela.altitud!),
    ].join(' · ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          child: SizedBox(
            height: 120,
            child: IgnorePointer(
              child: constructorMapa(
                latitud: parcela.latitud,
                longitud: parcela.longitud,
                puntoPuesto: true,
                alMoverPin: (_, _) {},
              ),
            ),
          ),
        ),
        const SizedBox(height: Medidas.espacioS),
        _Campo(
          etiqueta: Textos.etiquetaNombre,
          valor: parcela.nombre,
          alTocar: () => alCambiar(1),
        ),
        _Campo(
          etiqueta: Textos.etiquetaMunicipio,
          valor: Textos.municipio(parcela.municipio),
          alTocar: () => alCambiar(1),
        ),
        _Campo(
          etiqueta: Textos.etiquetaCultivoFase,
          valor: cultivo,
          alTocar: () => alCambiar(2),
        ),
        _Campo(
          etiqueta: Textos.coordenadas,
          valor:
              '${parcela.latitud.toStringAsFixed(4)}, '
              '${parcela.longitud.toStringAsFixed(4)}',
          alTocar: () => alCambiar(3),
        ),
        _Campo(
          etiqueta: Textos.etiquetaTamanoAltura,
          valor: tamano.isEmpty ? Textos.sinDato : tamano,
          alTocar: () => alCambiar(3),
        ),
      ],
    );
  }
}

/// Etiqueta y recuadro con el dato; tocarlo lleva a cambiarlo.
class _Campo extends StatelessWidget {
  const _Campo({
    required this.etiqueta,
    required this.valor,
    required this.alTocar,
  });

  final String etiqueta;
  final String valor;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final esClaro = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.only(bottom: Medidas.espacioS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: Tipografia.etiqueta.copyWith(
              fontSize: 15,
              color: esquema.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Semantics(
            button: true,
            label: '$etiqueta: $valor. ${Textos.cambiar}',
            excludeSemantics: true,
            child: Material(
              color: esquema.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Medidas.radioCampo),
                side: BorderSide(
                  color: esClaro ? Colores.bordeFuerte : Colores.bordeOscuro,
                  width: 2,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(Medidas.radioCampo),
                onTap: alTocar,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: Medidas.alturaCampo,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            valor,
                            style: Tipografia.cuerpoGrande.copyWith(
                              color: esquema.onSurface,
                            ),
                          ),
                        ),
                        Icon(
                          Symbols.edit,
                          size: 22,
                          color: esquema.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
