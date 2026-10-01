import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/aviso_error.dart';
import '../../componentes/boton_principal.dart';
import '../../componentes/campo_texto.dart';
import '../../config/tema/colores_semaforo.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/enums.dart';
import 'recuperar_contrasena_vm.dart';

/// Pantalla 07 · Recuperar contraseña. La confirmación queda en la misma
/// pantalla: el productor no pierde el contexto.
class RecuperarContrasenaPantalla extends StatelessWidget {
  const RecuperarContrasenaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecuperarContrasenaVm>();
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(Textos.recuperarTitulo)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text(
              Textos.recuperarDetalle,
              style: Tipografia.cuerpoGrande.copyWith(
                color: esquema.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Medidas.espacioM),
            CampoTexto(
              etiqueta: Textos.correo,
              icono: Symbols.mail,
              alCambiar: vm.cambiarCorreo,
              error: vm.errorCorreo,
              valido: vm.correoValido,
              teclado: TextInputType.emailAddress,
              accionTeclado: TextInputAction.done,
              autocompletar: const [AutofillHints.email],
              alEnviar: (_) => vm.enviar(),
            ),
            const SizedBox(height: Medidas.espacioM),
            if (vm.errorGeneral != null) ...[
              AvisoError(texto: vm.errorGeneral!),
              const SizedBox(height: Medidas.espacioS),
            ],
            BotonPrincipal(
              texto: Textos.enviarEnlace,
              textoCargando: Textos.enviandoEnlace,
              cargando: vm.enviando,
              alPresionar: () {
                FocusScope.of(context).unfocus();
                vm.enviar();
              },
            ),
            if (vm.enviado) ...[
              const SizedBox(height: Medidas.espacioM),
              const _TarjetaEnviado(),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaEnviado extends StatelessWidget {
  const _TarjetaEnviado();

  @override
  Widget build(BuildContext context) {
    final tono = ColoresSemaforo.of(context).de(NivelSeveridad.informativa);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tono.fondo,
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          border: Border.all(color: tono.borde, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Symbols.mark_email_read, size: 32, color: tono.icono),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Textos.enlaceEnviadoTitulo,
                    style: Tipografia.cuerpoGrande.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tono.texto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Textos.enlaceEnviadoDetalle,
                    style: Tipografia.cuerpo.copyWith(color: tono.texto),
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
