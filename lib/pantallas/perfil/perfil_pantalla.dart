import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/boton_secundario.dart';
import '../../config/textos.dart';
import '../shell/pantalla_en_construccion.dart';
import 'perfil_vm.dart';

/// Pantalla 28 · Perfil (provisional): mientras se construye, ofrece
/// "Cerrar sesión" para poder cambiar de cuenta (HU-02).
class PerfilPantalla extends StatelessWidget {
  const PerfilPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PerfilVm>();
    return PantallaEnConstruccion(
      titulo: Textos.navPerfil,
      accion: BotonSecundario(
        texto: vm.cerrando ? Textos.cerrandoSesion : Textos.cerrarSesion,
        icono: Symbols.logout,
        alPresionar: vm.cerrando ? null : vm.cerrarSesion,
      ),
    );
  }
}
