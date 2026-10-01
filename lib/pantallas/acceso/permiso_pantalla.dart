import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../componentes/boton_principal.dart';
import '../../componentes/boton_secundario.dart';
import '../../componentes/ilustracion_provisional.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import 'permiso_vm.dart';

/// Pantallas 08 (ubicación) y 09 (avisos): explican el beneficio y la
/// privacidad ANTES del diálogo del sistema (RNF-05).
class PermisoPantalla extends StatelessWidget {
  const PermisoPantalla({
    super.key,
    required this.icono,
    required this.colorIcono,
    required this.colorFondo,
    required this.colorBorde,
    required this.titulo,
    required this.detalle,
    required this.textoPermitir,
    required this.alTerminar,
  });

  final IconData icono;
  final Color colorIcono;
  final Color colorFondo;
  final Color colorBorde;
  final String titulo;
  final String detalle;
  final String textoPermitir;

  /// A dónde seguir después de "Permitir" o "Ahora no".
  final VoidCallback alTerminar;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PermisoVm>();
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Medidas.margenPantallaCentrada,
                  ),
                  child: Column(
                    children: [
                      IlustracionProvisional(
                        icono: icono,
                        colorIcono: colorIcono,
                        colorFondo: colorFondo,
                        colorBorde: colorBorde,
                      ),
                      const SizedBox(height: 26),
                      Text(
                        titulo,
                        textAlign: TextAlign.center,
                        style: Tipografia.titular.copyWith(
                          color: esquema.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        detalle,
                        textAlign: TextAlign.center,
                        style: Tipografia.cuerpoGrande.copyWith(
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
              child: Column(
                children: [
                  BotonPrincipal(
                    texto: textoPermitir,
                    cargando: vm.pidiendo,
                    alPresionar: () async {
                      await vm.permitir();
                      alTerminar();
                    },
                  ),
                  const SizedBox(height: Medidas.separacionTarjetas),
                  BotonSecundario(
                    texto: Textos.ahoraNo,
                    alPresionar: vm.pidiendo
                        ? null
                        : () async {
                            await vm.ahoraNo();
                            alTerminar();
                          },
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
