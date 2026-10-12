import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/dialogo_confirmar.dart';
import '../../componentes/grupo_opciones.dart';
import '../../config/rutas.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import 'ajustes_vm.dart';

/// Pantalla 29 · Ajustes: °C/°F, manzanas/ha, pantalla oscura, ahorrar datos
/// y, al final, cerrar sesión y eliminar la cuenta (con doble confirmación).
class AjustesPantalla extends StatelessWidget {
  const AjustesPantalla({super.key});

  Future<void> _eliminar(BuildContext context, AjustesVm vm) async {
    final mensajero = ScaffoldMessenger.of(context);
    final primera = await DialogoConfirmar.mostrar(
      context,
      icono: Symbols.delete,
      titulo: Textos.eliminarCuentaTitulo,
      detalle: Textos.eliminarCuentaDetalle,
      textoConfirmar: Textos.siSeguir,
      textoCancelar: Textos.noQuedarme,
    );
    if (!primera || !context.mounted) return;
    final segunda = await DialogoConfirmar.mostrar(
      context,
      icono: Symbols.warning,
      titulo: Textos.eliminarCuentaSeguro,
      detalle: Textos.eliminarCuentaNoVuelve,
      textoConfirmar: Textos.siEliminar,
      textoCancelar: Textos.noQuedarme,
    );
    if (!segunda) return;
    // Si sale bien, la sesión se cierra y el enrutador lleva a "Entrar".
    if (await vm.eliminarCuenta() == ResultadoEliminar.sinSenal) {
      mensajero.showSnackBar(
        const SnackBar(content: Text(Textos.eliminarSinSenal)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AjustesVm>();
    final esquema = Theme.of(context).colorScheme;
    final gris = esquema.onSurface;
    return Scaffold(
      appBar: AppBar(title: const Text(Textos.ajustes)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenPantalla,
          0,
          Medidas.margenPantalla,
          Medidas.espacioM,
        ),
        children: [
          const TituloGrupo(Textos.comoSeMuestran),
          GrupoOpciones(
            filas: [
              FilaOpcion(
                icono: Symbols.device_thermostat,
                texto: Textos.temperatura,
                color: gris,
                alFinal: _DosOpciones(
                  titulo: Textos.temperatura,
                  primera: Textos.celsius,
                  segunda: Textos.fahrenheit,
                  segundaElegida: vm.fahrenheit,
                  alCambiar: vm.cambiarFahrenheit,
                ),
              ),
              FilaOpcion(
                icono: Symbols.straighten,
                texto: Textos.terreno,
                color: gris,
                alFinal: _DosOpciones(
                  titulo: Textos.terreno,
                  primera: Textos.manzanasCorto,
                  segunda: Textos.hectareasCorto,
                  segundaElegida: vm.hectareas,
                  alCambiar: vm.cambiarHectareas,
                ),
              ),
              _Interruptor(
                icono: Symbols.dark_mode,
                texto: Textos.pantallaOscura,
                valor: vm.temaOscuro,
                alCambiar: vm.cambiarTemaOscuro,
              ),
            ],
          ),
          const TituloGrupo(Textos.internetYAvisos),
          GrupoOpciones(
            filas: [
              _Interruptor(
                icono: Symbols.data_saver_on,
                texto: Textos.ahorrarDatos,
                detalle: Textos.ahorrarDatosDetalle,
                valor: vm.ahorroDatos,
                alCambiar: vm.cambiarAhorroDatos,
              ),
              FilaOpcion(
                icono: Symbols.notifications,
                texto: Textos.misAvisos,
                color: gris,
                alTocar: () => context.push(Rutas.misAvisos),
              ),
            ],
          ),
          const SizedBox(height: Medidas.espacioM),
          GrupoOpciones(
            filas: [
              FilaOpcion(
                icono: Symbols.logout,
                texto: vm.cerrando
                    ? Textos.cerrandoSesion
                    : Textos.cerrarSesion,
                color: gris,
                conFlecha: false,
                alTocar: vm.eliminando || vm.cerrando ? null : vm.cerrarSesion,
              ),
              FilaOpcion(
                icono: Symbols.delete,
                texto: vm.eliminando
                    ? Textos.eliminandoCuenta
                    : Textos.eliminarMiCuenta,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colores.peligroBorde
                    : esquema.error,
                conFlecha: false,
                alTocar: vm.eliminando ? null : () => _eliminar(context, vm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fila con interruptor; toda la fila lo cambia.
class _Interruptor extends StatelessWidget {
  const _Interruptor({
    required this.icono,
    required this.texto,
    this.detalle,
    required this.valor,
    required this.alCambiar,
  });

  final IconData icono;
  final String texto;
  final String? detalle;
  final bool valor;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: FilaOpcion(
      icono: icono,
      texto: texto,
      detalle: detalle,
      color: Theme.of(context).colorScheme.onSurface,
      alTocar: () => alCambiar(!valor),
      alFinal: Switch(value: valor, onChanged: alCambiar),
    ),
  );
}

/// Dos pastillas, una elegida en verde ("°C · °F", "Manzanas · ha").
class _DosOpciones extends StatelessWidget {
  const _DosOpciones({
    required this.titulo,
    required this.primera,
    required this.segunda,
    required this.segundaElegida,
    required this.alCambiar,
  });

  final String titulo;
  final String primera;
  final String segunda;
  final bool segundaElegida;

  /// `true` = la segunda.
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Pastilla(
        texto: primera,
        grupo: titulo,
        elegida: !segundaElegida,
        alTocar: () => alCambiar(false),
      ),
      const SizedBox(width: 8),
      _Pastilla(
        texto: segunda,
        grupo: titulo,
        elegida: segundaElegida,
        alTocar: () => alCambiar(true),
      ),
    ],
  );
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({
    required this.texto,
    required this.grupo,
    required this.elegida,
    required this.alTocar,
  });

  final String texto;
  final String grupo;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final claro = Theme.of(context).brightness == Brightness.light;
    return Semantics(
      button: true,
      selected: elegida,
      label: '$grupo: $texto',
      excludeSemantics: true,
      child: Material(
        color: elegida
            ? (claro ? Colores.primario : esquema.primary)
            : esquema.surfaceContainerHighest,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 56,
              minHeight: Medidas.minimoTactil + 8,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  texto,
                  style: Tipografia.etiqueta.copyWith(
                    color: elegida
                        ? (claro ? Colors.white : esquema.onPrimary)
                        : esquema.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
