import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/boton_principal.dart';
import '../../componentes/boton_secundario.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../servicios/exportar_reporte.dart';
import 'reportes_pantalla.dart';
import 'reportes_vm.dart';

/// Abre "Guardar o enviar" (pantalla 27, D-51) sobre Reportes.
Future<void> mostrarExportarHoja(BuildContext context, ReportesVm vm) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          ChangeNotifierProvider.value(value: vm, child: const ExportarHoja()),
    );

/// Período, formato (PDF, Excel o CSV, cada uno con para qué sirve) y
/// "Compartir" o "Imprimir". El formato no se da por conocido: se dice con
/// palabras para qué sirve cada archivo.
class ExportarHoja extends StatelessWidget {
  const ExportarHoja({super.key});

  static IconData icono(FormatoReporte f) => switch (f) {
    FormatoReporte.pdf => Symbols.picture_as_pdf,
    FormatoReporte.excel => Symbols.table_chart,
    FormatoReporte.csv => Symbols.description,
  };

  static (String, String) textos(FormatoReporte f) => switch (f) {
    FormatoReporte.pdf => (Textos.archivoPdf, Textos.archivoPdfDetalle),
    FormatoReporte.excel => (Textos.hojaExcel, Textos.hojaExcelDetalle),
    FormatoReporte.csv => (Textos.archivoCsv, Textos.archivoCsvDetalle),
  };

  Future<void> _imprimir(BuildContext context, ReportesVm vm) async {
    final mensajero = ScaffoldMessenger.of(context);
    final resultado = await vm.imprimir();
    if (resultado == ResultadoExportar.sinImpresora) {
      mensajero.showSnackBar(
        const SnackBar(content: Text(Textos.noSePudoImprimir)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportesVm>();
    final esquema = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Textos.guardarOEnviar,
              style: Tipografia.titular.copyWith(color: esquema.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              Textos.seHaceArchivo,
              style: Tipografia.cuerpoGrande.copyWith(
                color: esquema.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Medidas.espacioS),
            SelectorPeriodo(vm: vm),
            const SizedBox(height: Medidas.espacioS),
            for (final formato in FormatoReporte.values) ...[
              _OpcionFormato(
                formato: formato,
                elegido: vm.formato == formato,
                alTocar: () => vm.elegirFormato(formato),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            BotonPrincipal(
              texto: Textos.compartir,
              icono: Symbols.share,
              cargando: vm.exportando,
              textoCargando: Textos.preparandoArchivo,
              alPresionar: vm.exportando ? null : vm.compartir,
            ),
            const SizedBox(height: 10),
            BotonSecundario(
              texto: Textos.imprimir,
              icono: Symbols.print,
              alPresionar: vm.exportando ? null : () => _imprimir(context, vm),
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

class _OpcionFormato extends StatelessWidget {
  const _OpcionFormato({
    required this.formato,
    required this.elegido,
    required this.alTocar,
  });

  final FormatoReporte formato;
  final bool elegido;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final (nombre, detalle) = ExportarHoja.textos(formato);
    final color = switch (formato) {
      FormatoReporte.pdf => Colores.peligroBorde,
      FormatoReporte.excel => Colores.primario,
      FormatoReporte.csv => esquema.onSurfaceVariant,
    };
    return Semantics(
      button: true,
      selected: elegido,
      label: '$nombre. $detalle',
      excludeSemantics: true,
      child: Material(
        color: elegido ? Colores.contenedorClaro : esquema.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          side: BorderSide(
            color: elegido ? Colores.primario : esquema.outlineVariant,
            width: elegido ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(ExportarHoja.icono(formato), size: 34, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: Tipografia.subtitulo.copyWith(
                          fontWeight: FontWeight.w700,
                          color: elegido
                              ? Colores.sobreContenedor
                              : esquema.onSurface,
                        ),
                      ),
                      Text(
                        detalle,
                        style: Tipografia.cuerpo.copyWith(
                          color: elegido
                              ? Colores.sobreContenedor
                              : esquema.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  elegido
                      ? Symbols.radio_button_checked
                      : Symbols.radio_button_unchecked,
                  color: elegido ? Colores.primario : esquema.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
