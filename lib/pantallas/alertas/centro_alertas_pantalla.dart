import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/esqueleto_carga.dart';
import '../../componentes/estado_vacio.dart';
import '../../config/rutas.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/alerta.dart';
import 'centro_alertas_vm.dart';
import 'tarjeta_alerta.dart';

/// Centro de alertas (pantallas 21 y 35, HU-11): pestañas Activos y
/// Anteriores. Sin alertas activas, "Todo tranquilo" en verde: un vacío de
/// alertas es una buena noticia.
class CentroAlertasPantalla extends StatelessWidget {
  const CentroAlertasPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CentroAlertasVm>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            Textos.avisos,
            style: Tipografia.titulo.copyWith(color: Colors.white),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colores.normalTextoOscuro,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
            labelStyle: Tipografia.subtitulo.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: Tipografia.subtitulo.copyWith(
              fontWeight: FontWeight.w400,
            ),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(child: _PestanaActivos(sinLeer: vm.sinLeer)),
              const Tab(text: Textos.anteriores),
            ],
          ),
        ),
        body: vm.cargando
            ? const _Cargando()
            : TabBarView(
                children: [
                  vm.activas.isEmpty
                      ? const EstadoVacio(
                          icono: Symbols.check_circle,
                          titulo: Textos.todoTranquilo,
                          detalle: Textos.todoTranquiloDetalle,
                        )
                      : _Lista(alertas: vm.activas, ahora: vm.ahora),
                  vm.anteriores.isEmpty
                      ? EstadoVacio(
                          icono: Symbols.history,
                          titulo: Textos.sinAnteriores,
                          detalle: Textos.sinAnterioresDetalle,
                          colorIcono: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                          colorDisco: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        )
                      : _Lista(alertas: vm.anteriores, ahora: vm.ahora),
                ],
              ),
      ),
    );
  }
}

class _PestanaActivos extends StatelessWidget {
  const _PestanaActivos({required this.sinLeer});

  final int sinLeer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: sinLeer == 0
          ? Textos.activos
          : '${Textos.activos}, ${Textos.sinLeer(sinLeer)}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(Textos.activos),
          if (sinLeer > 0) ...[
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 26),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colores.peligroBorde,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                '$sinLeer',
                textAlign: TextAlign.center,
                style: Tipografia.etiquetaChica.copyWith(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.alertas, required this.ahora});

  final List<Alerta> alertas;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(Medidas.margenPantalla),
      itemCount: alertas.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: Medidas.separacionTarjetas),
      itemBuilder: (context, i) => TarjetaAlerta(
        alerta: alertas[i],
        ahora: ahora,
        alTocar: () => context.push(Rutas.detalleAlerta(alertas[i].alertaId)),
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(Medidas.margenPantalla),
    children: const [
      EsqueletoCarga(alto: 150),
      SizedBox(height: Medidas.separacionTarjetas),
      EsqueletoCarga(alto: 150),
    ],
  );
}
