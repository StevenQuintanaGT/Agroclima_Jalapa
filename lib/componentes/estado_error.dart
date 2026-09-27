import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../config/tema/colores.dart';
import '../config/tema/medidas.dart';
import '../config/tema/tipografia.dart';
import '../config/textos.dart';
import 'boton_principal.dart';
import 'boton_secundario.dart';
import 'marco_punteado.dart';

/// Error de servicio (pantalla 34): causa probable en lenguaje llano, nunca
/// códigos. Siempre queda una acción útil: reintentar y, si hay, ver lo guardado.
class EstadoError extends StatelessWidget {
  const EstadoError({
    super.key,
    required this.alReintentar,
    this.alVerGuardados,
    this.titulo = Textos.errorServicioTitulo,
    this.detalle = Textos.errorServicioDetalle,
  });

  final VoidCallback alReintentar;
  final VoidCallback? alVerGuardados;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(Medidas.margenPantallaCentrada),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Marcador hasta tener la ilustración definitiva.
                    MarcoPunteado(
                      colorBorde: Colores.bordeFuerte,
                      colorFondo: Colores.fondoDatoGuardado,
                      radio: 20,
                      padding: EdgeInsets.zero,
                      child: const SizedBox(
                        width: 190,
                        height: 170,
                        child: Icon(
                          Symbols.cloud_alert,
                          size: 68,
                          color: Colores.textoTenue,
                        ),
                      ),
                    ),
                    const SizedBox(height: Medidas.espacioM),
                    Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: Tipografia.titulo.copyWith(
                        fontSize: 26,
                        color: esquema.onSurface,
                      ),
                    ),
                    const SizedBox(height: Medidas.espacioS),
                    Text(
                      detalle,
                      textAlign: TextAlign.center,
                      style: Tipografia.cuerpoGrande.copyWith(
                        height: 1.5,
                        color: esquema.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          BotonPrincipal(
            texto: Textos.intentarDeNuevo,
            icono: Symbols.refresh,
            alPresionar: alReintentar,
          ),
          if (alVerGuardados != null) ...[
            const SizedBox(height: Medidas.separacionTarjetas),
            BotonSecundario(
              texto: Textos.verDatosGuardados,
              alPresionar: alVerGuardados,
            ),
          ],
        ],
      ),
    );
  }
}
