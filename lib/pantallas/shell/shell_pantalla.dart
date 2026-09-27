import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../config/tema/colores.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';

/// Contenedor con la barra inferior de 5 destinos (docs/DISENO_UI.md §8).
/// Ícono y palabra siempre visibles; nunca solo ícono.
class ShellPantalla extends StatelessWidget {
  const ShellPantalla({
    super.key,
    required this.navegacion,
    this.alertasNoLeidas = 0,
  });

  final StatefulNavigationShell navegacion;

  /// Número del distintivo rojo en "Alertas" (lo aporta HU-11).
  final int alertasNoLeidas;

  static const _destinos = [
    (icono: Symbols.home, etiqueta: Textos.navInicio),
    (icono: Symbols.map, etiqueta: Textos.navMapa),
    (icono: Symbols.notifications, etiqueta: Textos.navAlertas),
    (icono: Symbols.bar_chart, etiqueta: Textos.navReportes),
    (icono: Symbols.person, etiqueta: Textos.navPerfil),
  ];

  static const int indiceAlertas = 2;

  void _irA(int indice) {
    // Tocar el destino actual vuelve a su pantalla inicial.
    navegacion.goBranch(
      indice,
      initialLocation: indice == navegacion.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navegacion,
      bottomNavigationBar: _BarraInferior(
        indiceActual: navegacion.currentIndex,
        alertasNoLeidas: alertasNoLeidas,
        alTocar: _irA,
      ),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({
    required this.indiceActual,
    required this.alertasNoLeidas,
    required this.alTocar,
  });

  final int indiceActual;
  final int alertasNoLeidas;
  final ValueChanged<int> alTocar;

  @override
  Widget build(BuildContext context) {
    final esClaro = Theme.of(context).brightness == Brightness.light;
    final esquema = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: esquema.surface,
        border: Border(
          top: BorderSide(
            color: esClaro ? Colores.bordeBarraInferior : Colores.bordeOscuro,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: Row(
            children: [
              for (var i = 0; i < ShellPantalla._destinos.length; i++)
                Expanded(
                  child: _ItemBarra(
                    icono: ShellPantalla._destinos[i].icono,
                    etiqueta: ShellPantalla._destinos[i].etiqueta,
                    activo: i == indiceActual,
                    distintivo: i == ShellPantalla.indiceAlertas
                        ? alertasNoLeidas
                        : 0,
                    alTocar: () => alTocar(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemBarra extends StatelessWidget {
  const _ItemBarra({
    required this.icono,
    required this.etiqueta,
    required this.activo,
    required this.distintivo,
    required this.alTocar,
  });

  final IconData icono;
  final String etiqueta;
  final bool activo;
  final int distintivo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esClaro = Theme.of(context).brightness == Brightness.light;
    final color = activo
        ? (esClaro ? Colores.primarioOscuro : Colores.primarioTemaOscuro)
        : (esClaro ? Colores.navegacionInactiva : Colores.textoTenueOscuro);

    return Semantics(
      button: true,
      selected: activo,
      label: distintivo > 0 ? '$etiqueta, $distintivo' : etiqueta,
      excludeSemantics: true,
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: distintivo > 0,
                label: Text('$distintivo'),
                backgroundColor: Colores.peligroBorde,
                textStyle: Tipografia.etiquetaChica.copyWith(fontSize: 11),
                child: Icon(icono, size: 26, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Tipografia.etiquetaChica.copyWith(
                  color: color,
                  fontWeight: activo ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
