import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/aviso_error.dart';
import '../../componentes/boton_principal.dart';
import '../../componentes/boton_secundario.dart';
import '../../componentes/campo_texto.dart';
import '../../componentes/logo_app.dart';
import '../../config/rutas.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import 'inicio_sesion_vm.dart';

/// Pantalla 05 · Entre a su cuenta (HU-02).
class InicioSesionPantalla extends StatelessWidget {
  const InicioSesionPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InicioSesionVm>();
    final esquema = Theme.of(context).colorScheme;
    final enlace = Theme.of(context).brightness == Brightness.light
        ? Colores.primarioOscuro
        : Colores.primarioTemaOscuro;

    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        const LogoApp(tamano: 56),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Textos.marca,
                              style: Tipografia.titular.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                color: esquema.onSurface,
                              ),
                            ),
                            Text(
                              Textos.marcaLugar,
                              style: Tipografia.subtitulo.copyWith(
                                fontWeight: FontWeight.w500,
                                color: esquema.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: Medidas.espacioM),
                    Text(
                      Textos.entrarTitulo,
                      style: Tipografia.titulo.copyWith(
                        fontSize: 28,
                        color: esquema.onSurface,
                      ),
                    ),
                    const SizedBox(height: Medidas.espacioM),
                    CampoTexto(
                      etiqueta: Textos.correo,
                      icono: Symbols.mail,
                      alCambiar: vm.cambiarCorreo,
                      error: vm.errorCorreo,
                      teclado: TextInputType.emailAddress,
                      autocompletar: const [AutofillHints.email],
                    ),
                    const SizedBox(height: Medidas.espacioS),
                    CampoTexto(
                      etiqueta: Textos.contrasena,
                      icono: Symbols.lock,
                      alCambiar: vm.cambiarContrasena,
                      error: vm.errorContrasena,
                      esContrasena: true,
                      accionTeclado: TextInputAction.done,
                      autocompletar: const [AutofillHints.password],
                      alEnviar: (_) => vm.entrar(),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: vm.ocupado
                            ? null
                            : () => context.push(Rutas.recuperar),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(Textos.olvideContrasena),
                      ),
                    ),
                    if (vm.errorGeneral != null) ...[
                      AvisoError(texto: vm.errorGeneral!),
                      const SizedBox(height: Medidas.espacioS),
                    ],
                    BotonPrincipal(
                      texto: Textos.entrar,
                      textoCargando: Textos.entrando,
                      cargando: vm.cargando,
                      alPresionar: vm.cargandoGoogle
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              vm.entrar();
                            },
                    ),
                    const SizedBox(height: Medidas.espacioS),
                    const _DivisorO(),
                    const SizedBox(height: Medidas.espacioS),
                    BotonSecundario(
                      texto: vm.cargandoGoogle
                          ? Textos.entrando
                          : Textos.entrarConGoogle,
                      icono: Symbols.account_circle,
                      alPresionar: vm.ocupado ? null : vm.entrarConGoogle,
                    ),
                  ],
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        Textos.sinCuenta,
                        textAlign: TextAlign.center,
                        style: Tipografia.cuerpoGrande.copyWith(
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: vm.ocupado
                            ? null
                            : () => context.push(Rutas.registro),
                        child: Text(
                          Textos.crearCuenta,
                          style: Tipografia.cuerpoGrande.copyWith(
                            fontWeight: FontWeight.w700,
                            color: enlace,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DivisorO extends StatelessWidget {
  const _DivisorO();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            Textos.o,
            style: Tipografia.cuerpo.copyWith(color: color),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
