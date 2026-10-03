import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/boton_principal.dart';
import '../../componentes/ilustracion_provisional.dart';
import '../../config/rutas.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import 'bienvenida_vm.dart';

/// Pantallas 02–04 · Bienvenida en 3 ideas.
class BienvenidaPantalla extends StatefulWidget {
  const BienvenidaPantalla({super.key});

  @override
  State<BienvenidaPantalla> createState() => _BienvenidaPantallaState();
}

class _BienvenidaPantallaState extends State<BienvenidaPantalla> {
  final _paginas = PageController();

  static const _pasos = [
    (
      icono: Symbols.pin_drop,
      color: Colores.primario,
      fondo: Colores.contenedorClaro,
      borde: Colores.bordeIlustracionVerde,
      titulo: Textos.onboarding1Titulo,
      detalle: Textos.onboarding1Detalle,
    ),
    (
      icono: Symbols.thermostat,
      color: Colores.acentoCielo,
      fondo: Colores.cieloClaro,
      borde: Colores.bordeIlustracionCielo,
      titulo: Textos.onboarding2Titulo,
      detalle: Textos.onboarding2Detalle,
    ),
    (
      icono: Symbols.notifications_active,
      color: Colores.precaucionIcono,
      fondo: Colores.precaucionFondo,
      borde: Colores.bordeIlustracionAmbar,
      titulo: Textos.onboarding3Titulo,
      detalle: Textos.onboarding3Detalle,
    ),
  ];

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  Future<void> _terminar(BienvenidaVm vm) async {
    await vm.terminar();
    // Primer uso: va directo a crear cuenta; "atrás" lleva a entrar.
    if (mounted) context.go(Rutas.registro);
  }

  void _siguiente(BienvenidaVm vm) {
    if (vm.esUltimo) {
      _terminar(vm);
    } else {
      _paginas.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BienvenidaVm>();
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: Medidas.minimoTactil,
              child: Align(
                alignment: Alignment.centerRight,
                child: vm.esUltimo
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: TextButton(
                          onPressed: () => _terminar(vm),
                          child: const Text(Textos.omitir),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _paginas,
                itemCount: _pasos.length,
                onPageChanged: vm.irAPaso,
                itemBuilder: (context, i) {
                  final paso = _pasos[i];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.sizeOf(context).height * 0.6,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IlustracionProvisional(
                            icono: paso.icono,
                            colorIcono: paso.color,
                            colorFondo: paso.fondo,
                            colorBorde: paso.borde,
                          ),
                          const SizedBox(height: 26),
                          Text(
                            paso.titulo,
                            textAlign: TextAlign.center,
                            style: Tipografia.titular.copyWith(
                              color: esquema.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            paso.detalle,
                            textAlign: TextAlign.center,
                            style: Tipografia.cuerpoGrande.copyWith(
                              color: esquema.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _IndicadorPasos(actual: vm.paso, total: _pasos.length),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
              child: BotonPrincipal(
                texto: vm.esUltimo ? Textos.empezar : Textos.siguiente,
                alPresionar: () => _siguiente(vm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicadorPasos extends StatelessWidget {
  const _IndicadorPasos({required this.actual, required this.total});

  final int actual;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Paso ${actual + 1} de $total',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == actual ? 28 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: i == actual
                    ? Colores.primario
                    : Colores.indicadorInactivo,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
        ],
      ),
    );
  }
}
