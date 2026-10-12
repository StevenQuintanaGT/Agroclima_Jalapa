import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../componentes/boton_principal.dart';
import '../../componentes/boton_secundario.dart';
import '../../componentes/campo_texto.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../utilidades/validadores.dart';
import 'perfil_vm.dart';

/// Abre "Cambiar mis datos" sobre el perfil.
Future<void> mostrarDatosHoja(BuildContext context, PerfilVm vm) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          ChangeNotifierProvider.value(value: vm, child: const DatosHoja()),
    );

/// Nombre y teléfono, con las mismas reglas del registro (Tabla 48). El
/// correo es el de la cuenta y no se cambia.
class DatosHoja extends StatefulWidget {
  const DatosHoja({super.key});

  @override
  State<DatosHoja> createState() => _DatosHojaState();
}

class _DatosHojaState extends State<DatosHoja> {
  late String _nombre;
  late String _telefono;
  bool _intento = false;

  @override
  void initState() {
    super.initState();
    final vm = context.read<PerfilVm>();
    _nombre = vm.usuario?.nombre ?? '';
    _telefono = vm.telefonoLocal;
  }

  Future<void> _guardar() async {
    setState(() => _intento = true);
    final vm = context.read<PerfilVm>();
    final navegador = Navigator.of(context);
    final mensajero = ScaffoldMessenger.of(context);
    final guardado = await vm.guardarDatos(
      nombre: _nombre,
      telefono: _telefono,
    );
    if (!guardado) return;
    navegador.pop();
    mensajero.showSnackBar(
      const SnackBar(content: Text(Textos.datosGuardados)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PerfilVm>();
    final esquema = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Textos.cambiarMisDatos,
              style: Tipografia.titular.copyWith(color: esquema.onSurface),
            ),
            const SizedBox(height: Medidas.espacioS),
            CampoTexto(
              etiqueta: Textos.nombreCompleto,
              valorInicial: _nombre,
              alCambiar: (valor) => setState(() => _nombre = valor),
              error: _intento ? Validadores.nombre(_nombre) : null,
              teclado: TextInputType.name,
            ),
            const SizedBox(height: Medidas.espacioS),
            CampoTexto(
              etiqueta: Textos.telefono,
              valorInicial: _telefono,
              alCambiar: (valor) => setState(() => _telefono = valor),
              error: _intento ? Validadores.telefono(_telefono) : null,
              prefijo: Textos.prefijoGuatemala,
              teclado: TextInputType.phone,
              accionTeclado: TextInputAction.done,
              formatos: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 -]')),
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: Medidas.espacioS),
            Text(
              '${vm.usuario?.correo ?? ''}\n${Textos.correoNoCambia}',
              style: Tipografia.cuerpo.copyWith(
                color: esquema.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Medidas.espacioM),
            BotonPrincipal(
              texto: Textos.guardarCambios,
              cargando: vm.guardando,
              alPresionar: vm.guardando ? null : _guardar,
            ),
            const SizedBox(height: 10),
            BotonSecundario(
              texto: Textos.cancelar,
              alPresionar: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
