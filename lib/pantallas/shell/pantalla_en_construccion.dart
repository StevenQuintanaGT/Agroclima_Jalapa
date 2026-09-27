import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../componentes/estado_vacio.dart';
import '../../config/textos.dart';

/// Marcador para los destinos que se construyen en etapas posteriores.
/// Se reemplaza pantalla por pantalla según docs/PLAN_DE_TRABAJO.md.
class PantallaEnConstruccion extends StatelessWidget {
  const PantallaEnConstruccion({
    super.key,
    required this.titulo,
    this.conBarra = true,
  });

  final String titulo;
  final bool conBarra;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: conBarra ? AppBar(title: Text(titulo)) : null,
      body: const SafeArea(
        child: EstadoVacio(
          icono: Symbols.agriculture,
          titulo: Textos.enConstruccionTitulo,
          detalle: Textos.enConstruccionDetalle,
        ),
      ),
    );
  }
}
