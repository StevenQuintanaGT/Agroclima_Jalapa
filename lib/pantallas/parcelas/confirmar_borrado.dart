import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../componentes/dialogo_confirmar.dart';
import '../../config/textos.dart';
import 'mis_parcelas_vm.dart';

/// Pregunta antes de borrar (pantalla 15) y, si confirma, borra y avisa.
/// Devuelve `true` si la parcela se borró (aunque falte subirlo).
Future<bool> confirmarBorrado(
  BuildContext context, {
  required String nombre,
  required Future<ResultadoBorrado> Function() borrar,
}) async {
  final confirmo = await DialogoConfirmar.mostrar(
    context,
    icono: Symbols.delete_forever,
    titulo: Textos.preguntaBorrar(nombre),
    detalle: Textos.detalleBorrar,
    textoConfirmar: Textos.siBorrar,
    textoCancelar: Textos.noQuedarme,
  );
  if (!confirmo || !context.mounted) return false;
  final mensajero = ScaffoldMessenger.of(context);
  final resultado = await borrar();
  mensajero.showSnackBar(
    SnackBar(
      content: Text(switch (resultado) {
        ResultadoBorrado.borrada => Textos.parcelaBorrada,
        ResultadoBorrado.borradaSinSenal => Textos.borradaSinSenal,
        ResultadoBorrado.error => Textos.errorGenerico,
      }),
    ),
  );
  return resultado != ResultadoBorrado.error;
}
