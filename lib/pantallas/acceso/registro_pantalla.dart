import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/aviso_error.dart';
import '../../componentes/boton_principal.dart';
import '../../componentes/campo_texto.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import 'registro_vm.dart';

/// Pantalla 06 · Crear cuenta (HU-01).
class RegistroPantalla extends StatelessWidget {
  const RegistroPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistroVm>();
    return Scaffold(
      appBar: AppBar(title: const Text(Textos.crearCuenta)),
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              CampoTexto(
                etiqueta: Textos.nombreCompleto,
                alCambiar: vm.cambiarNombre,
                error: vm.errorNombre,
                valido: vm.nombreValido,
                teclado: TextInputType.name,
                autocompletar: const [AutofillHints.name],
              ),
              const SizedBox(height: Medidas.espacioS),
              CampoTexto(
                etiqueta: Textos.telefono,
                alCambiar: vm.cambiarTelefono,
                error: vm.errorTelefono,
                valido: vm.telefonoValido,
                prefijo: Textos.prefijoGuatemala,
                teclado: TextInputType.phone,
                autocompletar: const [AutofillHints.telephoneNumberNational],
                formatos: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 -]')),
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              const SizedBox(height: Medidas.espacioS),
              CampoTexto(
                etiqueta: Textos.correo,
                alCambiar: vm.cambiarCorreo,
                error: vm.errorCorreo,
                valido: vm.correoValido,
                teclado: TextInputType.emailAddress,
                autocompletar: const [AutofillHints.email],
              ),
              const SizedBox(height: Medidas.espacioS),
              CampoTexto(
                etiqueta: Textos.creeContrasena,
                alCambiar: vm.cambiarContrasena,
                error: vm.errorContrasena,
                ayuda: Textos.ayudaContrasena,
                esContrasena: true,
                autocompletar: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: Medidas.espacioS),
              CampoTexto(
                etiqueta: Textos.repetirContrasena,
                alCambiar: vm.cambiarRepetir,
                error: vm.errorRepetir,
                valido: vm.repetirValida,
                esContrasena: true,
                accionTeclado: TextInputAction.done,
                autocompletar: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: Medidas.espacioS),
              _CasillaTerminos(
                marcada: vm.aceptaTerminos,
                alCambiar: vm.cambiarTerminos,
              ),
              if (vm.errorGeneral != null) ...[
                const SizedBox(height: Medidas.espacioS),
                AvisoError(texto: vm.errorGeneral!),
              ],
              const SizedBox(height: Medidas.espacioM),
              BotonPrincipal(
                texto: Textos.crearMiCuenta,
                textoCargando: Textos.creandoCuenta,
                cargando: vm.cargando,
                alPresionar: vm.puedeEnviar
                    ? () {
                        FocusScope.of(context).unfocus();
                        vm.registrar();
                      }
                    : null,
              ),
              if (!vm.aceptaTerminos) ...[
                const SizedBox(height: Medidas.espacioXs),
                Text(
                  Textos.errorTerminos,
                  textAlign: TextAlign.center,
                  style: Tipografia.cuerpoChico.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CasillaTerminos extends StatelessWidget {
  const _CasillaTerminos({required this.marcada, required this.alCambiar});

  final bool marcada;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final esClaro = Theme.of(context).brightness == Brightness.light;
    final estilo = Tipografia.cuerpo.copyWith(color: esquema.onSurfaceVariant);
    return Semantics(
      checked: marcada,
      label:
          '${Textos.aceptoTerminosAntes}${Textos.terminosDeUso}'
          '${Textos.aceptoTerminosDespues}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => alCambiar(!marcada),
        borderRadius: BorderRadius.circular(Medidas.radioCampo),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Medidas.minimoTactil),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: marcada ? esquema.primary : esquema.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: marcada ? esquema.primary : esquema.outline,
                    width: 2,
                  ),
                ),
                child: marcada
                    ? Icon(Symbols.check, size: 20, color: esquema.onPrimary)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: estilo,
                    children: [
                      const TextSpan(text: Textos.aceptoTerminosAntes),
                      TextSpan(
                        text: Textos.terminosDeUso,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: esClaro
                              ? Colores.primarioOscuro
                              : Colores.primarioTemaOscuro,
                        ),
                      ),
                      const TextSpan(text: Textos.aceptoTerminosDespues),
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
