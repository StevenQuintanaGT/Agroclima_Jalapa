import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/boton_secundario.dart';
import '../../componentes/grupo_opciones.dart';
import '../../config/rutas.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import 'datos_hoja.dart';
import 'perfil_vm.dart';

/// Pantalla 28 · Perfil: quién es, cuántas parcelas tiene y dónde, accesos a
/// parcelas, avisos, ajustes y ayuda, y "Cerrar sesión" (HU-02).
class PerfilPantalla extends StatelessWidget {
  const PerfilPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PerfilVm>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Encabezado(vm: vm),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.margenPantalla,
                Medidas.espacioM,
                Medidas.margenPantalla,
                Medidas.espacioM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GrupoOpciones(
                    filas: [
                      FilaOpcion(
                        icono: Symbols.agriculture,
                        texto: Textos.misParcelas,
                        alTocar: () => context.push(Rutas.misParcelas),
                      ),
                      FilaOpcion(
                        icono: Symbols.notifications,
                        texto: Textos.misAvisos,
                        alTocar: () => context.push(Rutas.misAvisos),
                      ),
                      FilaOpcion(
                        icono: Symbols.settings,
                        texto: Textos.ajustes,
                        alTocar: () => context.push(Rutas.ajustes),
                      ),
                      FilaOpcion(
                        icono: Symbols.help,
                        texto: Textos.ayuda,
                        alTocar: () => context.push(Rutas.ayuda),
                      ),
                    ],
                  ),
                  const SizedBox(height: Medidas.espacioM),
                  BotonSecundario(
                    texto: vm.cerrando
                        ? Textos.cerrandoSesion
                        : Textos.cerrarSesion,
                    alPresionar: vm.cerrando ? null : vm.cerrarSesion,
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

/// Franja verde con las iniciales, el nombre, el correo y
/// "Jalapa · 3 parcelas". "Cambiar mis datos" abre la hoja de nombre y
/// teléfono.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.vm});

  final PerfilVm vm;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final usuario = vm.usuario;
    final municipio = vm.municipio;
    final resumen = Textos.resumenPerfil(
      municipio == null ? null : Textos.municipio(municipio),
      vm.cantidadParcelas,
    );
    const blanco = Colors.white;
    final tenue = blanco.withValues(alpha: 0.88);
    return Container(
      color: tema.appBarTheme.backgroundColor,
      padding: EdgeInsets.fromLTRB(
        Medidas.margenPantalla,
        MediaQuery.paddingOf(context).top + Medidas.espacioM,
        Medidas.margenPantalla,
        Medidas.espacioS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colores.primarioTemaOscuro,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    usuario?.iniciales ?? '',
                    style: Tipografia.datoGrande.copyWith(
                      color: Colores.sobreContenedor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario?.nombre ?? '',
                      style: Tipografia.titular.copyWith(color: blanco),
                    ),
                    if (usuario != null)
                      Text(
                        usuario.correo,
                        style: Tipografia.cuerpoGrande.copyWith(color: tenue),
                      ),
                    if (resumen.isNotEmpty)
                      Text(
                        resumen,
                        style: Tipografia.cuerpoGrande.copyWith(color: tenue),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (usuario != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => mostrarDatosHoja(context, vm),
                style: TextButton.styleFrom(
                  foregroundColor: blanco,
                  minimumSize: const Size(0, Medidas.minimoTactil),
                ),
                icon: const Icon(Symbols.edit, size: 22),
                label: Text(
                  Textos.cambiarMisDatos,
                  style: Tipografia.etiqueta.copyWith(color: blanco),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
