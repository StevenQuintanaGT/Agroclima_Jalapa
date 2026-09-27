import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../config/tema/colores.dart';
import '../config/tema/tipografia.dart';
import '../config/textos.dart';

/// Banner persistente bajo la barra superior cuando no hay internet
/// (pantalla 32). Sin conexión es el caso normal, no la excepción (HU-15).
class AvisoNoVigente extends StatelessWidget {
  const AvisoNoVigente({
    super.key,
    this.titulo = Textos.sinInternetTitulo,
    this.detalle = Textos.sinInternetDetalle,
  });

  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: Colores.bannerSinConexion,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Symbols.cloud_off, size: 26, color: Colors.white),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Tipografia.cuerpo.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    detalle,
                    style: Tipografia.cuerpoChico.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
