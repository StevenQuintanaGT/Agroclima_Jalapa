import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/boton_principal.dart';
import '../../componentes/esqueleto_carga.dart';
import '../../componentes/estado_error.dart';
import '../../componentes/estado_vacio.dart';
import '../../componentes/ilustracion_provisional.dart';
import '../../config/rutas.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/parcela.dart';
import 'confirmar_borrado.dart';
import 'mis_parcelas_vm.dart';
import 'tarjeta_parcela.dart';

/// Pantallas 14 y 16 · Mis parcelas (HU-06): tarjetas deslizables con
/// "Editar" y "Borrar", y estado vacío con un solo botón para registrar.
class MisParcelasPantalla extends StatelessWidget {
  const MisParcelasPantalla({super.key});

  void _agregar(BuildContext context) => context.push(Rutas.nuevaParcela);

  Future<void> _borrar(
    BuildContext context,
    MisParcelasVm vm,
    Parcela parcela,
  ) => confirmarBorrado(
    context,
    nombre: parcela.nombre,
    borrar: () => vm.borrar(parcela),
  );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MisParcelasVm>();
    final conLista = !vm.cargando && !vm.error && !vm.vacia;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: conLista ? 72 : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(Textos.misParcelas),
            if (conLista)
              Text(
                Textos.terrenosRegistrados(vm.parcelas.length),
                style: Tipografia.cuerpo.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: conLista
          ? FloatingActionButton.extended(
              onPressed: () => _agregar(context),
              backgroundColor: Colores.primario,
              foregroundColor: Colors.white,
              extendedTextStyle: Tipografia.boton.copyWith(fontSize: 18),
              shape: const StadiumBorder(),
              icon: const Icon(Symbols.add, size: 28),
              label: const Text(Textos.agregarParcela),
            )
          : null,
      body: SafeArea(
        child: switch (vm) {
          MisParcelasVm(cargando: true) => const _Cargando(),
          MisParcelasVm(error: true) => EstadoError(
            titulo: Textos.errorParcelasTitulo,
            detalle: Textos.errorParcelasDetalle,
            alReintentar: vm.reintentar,
          ),
          MisParcelasVm(vacia: true) => EstadoVacio(
            icono: Symbols.agriculture,
            titulo: Textos.vacioParcelasTitulo,
            detalle: Textos.vacioParcelasDetalle,
            ilustracion: const IlustracionProvisional(
              icono: Symbols.agriculture,
              colorIcono: Colores.primario,
              colorFondo: Colores.contenedorClaro,
              colorBorde: Colores.bordeIlustracionVerde,
              ancho: 190,
              alto: 170,
            ),
            accion: BotonPrincipal(
              texto: Textos.registrarParcela,
              icono: Symbols.add,
              alPresionar: () => _agregar(context),
            ),
          ),
          _ => ListView.separated(
            // Abajo queda lugar para el botón flotante.
            padding: const EdgeInsets.fromLTRB(
              Medidas.margenPantalla,
              14,
              Medidas.margenPantalla,
              96,
            ),
            itemCount: vm.parcelas.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: Medidas.separacionTarjetas),
            itemBuilder: (context, i) {
              final parcela = vm.parcelas[i];
              return TarjetaParcela(
                key: ValueKey(parcela.parcelaId),
                parcela: parcela,
                // TODO(HU-07, HU-10): temperatura actual y nivel de alertas.
                alTocar: () =>
                    context.push(Rutas.detalleParcela(parcela.parcelaId)),
                alEditar: () => context.push(
                  Rutas.editarParcela(parcela.parcelaId),
                  extra: parcela,
                ),
                alBorrar: () => _borrar(context, vm, parcela),
              );
            },
          ),
        },
      ),
    );
  }
}

/// Esqueleto con la forma de las tarjetas (pantalla 33).
class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Medidas.margenPantalla),
      children: [
        for (var i = 0; i < 3; i++) ...const [
          EsqueletoCarga(alto: 110, radio: Medidas.radioTarjeta),
          SizedBox(height: Medidas.separacionTarjetas),
        ],
      ],
    );
  }
}
