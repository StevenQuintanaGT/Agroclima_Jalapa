import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../componentes/barra_progreso_pasos.dart';
import '../../componentes/boton_principal.dart';
import '../../config/rutas.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import 'mapa_parcela.dart';
import 'paso_cultivo.dart';
import 'paso_mapa.dart';
import 'paso_nombre.dart';
import 'paso_revision.dart';
import 'registro_parcela_vm.dart';

/// Pantallas 10–13 · Registro de parcela en 4 pasos con barra de progreso
/// (HU-03, HU-04, HU-05; RNF-12).
class RegistroParcelaPantalla extends StatelessWidget {
  const RegistroParcelaPantalla({
    super.key,
    this.constructorMapa = MapaParcela.construir,
  });

  final ConstructorMapa constructorMapa;

  static String _titulo(int paso) => switch (paso) {
    3 => Textos.tituloPaso3,
    4 => Textos.tituloPaso4,
    _ => Textos.nuevaParcela,
  };

  void _atras(BuildContext context, RegistroParcelaVm vm) {
    if (!vm.atras() && context.canPop()) context.pop();
  }

  Future<void> _guardar(BuildContext context, RegistroParcelaVm vm) async {
    final resultado = await vm.guardar();
    if (!context.mounted || resultado == ResultadoGuardado.error) return;
    final mensajero = ScaffoldMessenger.of(context);
    if (resultado == ResultadoGuardado.guardadaSinSenal) {
      mensajero.showSnackBar(
        const SnackBar(content: Text(Textos.guardadaSinSenal)),
      );
    }
    // TODO(HU-06): ir a "Mis parcelas" con la nueva parcela.
    context.go(Rutas.inicio);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistroParcelaVm>();
    final esUltimo = vm.paso == RegistroParcelaVm.totalPasos;
    return PopScope(
      canPop: vm.paso == 1,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) vm.atras();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 72,
          leading: BackButton(onPressed: () => _atras(context, vm)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_titulo(vm.paso)),
              Text(
                Textos.pasoDe(vm.paso, RegistroParcelaVm.totalPasos),
                style: Tipografia.cuerpoChico.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: BarraProgresoPasos(
                actual: vm.paso,
                total: RegistroParcelaVm.totalPasos,
              ),
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: switch (vm.paso) {
            1 => const PasoNombre(),
            2 => const PasoCultivo(),
            3 => PasoMapa(constructorMapa: constructorMapa),
            _ => PasoRevision(constructorMapa: constructorMapa),
          },
        ),
        bottomNavigationBar: _Pie(
          child: BotonPrincipal(
            texto: esUltimo ? Textos.guardarParcela : Textos.siguiente,
            textoCargando: Textos.guardandoParcela,
            cargando: vm.guardando,
            alPresionar: () {
              FocusScope.of(context).unfocus();
              if (esUltimo) {
                _guardar(context, vm);
              } else {
                vm.siguiente();
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Pie fijo blanco con borde superior (pantallas 10–13).
class _Pie extends StatelessWidget {
  const _Pie({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final esClaro = Theme.of(context).brightness == Brightness.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: esClaro ? Colores.bordeBarraInferior : Colores.bordeOscuro,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: child,
        ),
      ),
    );
  }
}
