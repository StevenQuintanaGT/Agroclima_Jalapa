import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/boton_secundario.dart';
import '../../config/rutas.dart';
import '../../config/tema/medidas.dart';
import '../../config/textos.dart';
import '../shell/pantalla_en_construccion.dart';
import 'perfil_vm.dart';

/// Pantalla 28 · Perfil (provisional): mientras se construye, lleva a "Mis
/// parcelas" (HU-06) y ofrece "Cerrar sesión" para cambiar de cuenta (HU-02).
class PerfilPantalla extends StatelessWidget {
  const PerfilPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PerfilVm>();
    return PantallaEnConstruccion(
      titulo: Textos.navPerfil,
      accion: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BotonSecundario(
            texto: Textos.misParcelas,
            icono: Symbols.agriculture,
            alPresionar: () => context.push(Rutas.misParcelas),
          ),
          const SizedBox(height: Medidas.espacioXs),
          BotonSecundario(
            texto: vm.cerrando ? Textos.cerrandoSesion : Textos.cerrarSesion,
            icono: Symbols.logout,
            alPresionar: vm.cerrando ? null : vm.cerrarSesion,
          ),
        ],
      ),
    );
  }
}
