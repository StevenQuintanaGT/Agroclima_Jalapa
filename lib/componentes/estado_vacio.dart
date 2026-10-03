import 'package:flutter/material.dart';

import '../config/tema/colores.dart';
import '../config/tema/medidas.dart';
import '../config/tema/tipografia.dart';

/// Pantalla sin contenido (pantallas 16 y 35): disco con ícono, título,
/// explicación y, si hay, la única acción posible al pie, donde alcanza el pulgar.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.colorIcono = Colores.primario,
    this.colorDisco = Colores.contenedorClaro,
    this.accion,
    this.ilustracion,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final Color colorIcono;
  final Color colorDisco;

  /// Normalmente un [BotonPrincipal].
  final Widget? accion;

  /// Reemplaza al disco con ícono (p. ej. el recuadro punteado de la 16).
  final Widget? ilustracion;

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
                    ilustracion ??
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: colorDisco,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icono, size: 66, color: colorIcono),
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
          if (accion != null) ...[
            const SizedBox(height: Medidas.espacioS),
            accion!,
          ],
        ],
      ),
    );
  }
}
