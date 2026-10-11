import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/aviso_apoyo.dart';
import '../../componentes/boton_secundario.dart';
import '../../componentes/chip_seleccion.dart';
import '../../componentes/esqueleto_carga.dart';
import '../../componentes/estado_vacio.dart';
import '../../config/rutas.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/colores_semaforo.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/enums.dart';
import '../../servicios/reportes_servicio.dart';
import 'exportar_hoja.dart';
import 'graficas_reporte.dart';
import 'reportes_vm.dart';

/// Reportes (pantalla 25, HU-16): resumen de una parcela en 7 o 30 días o
/// en los días que elija, con 4 indicadores y 2 gráficas que se explican
/// con una frase. "Enviar" abre "Guardar o enviar" (27, D-51).
class ReportesPantalla extends StatelessWidget {
  const ReportesPantalla({super.key});

  void _elegirParcela(BuildContext context, ReportesVm vm) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(Textos.elegirParcela, style: Tipografia.subtitulo),
            ),
            for (final parcela in vm.parcelas)
              ListTile(
                minTileHeight: Medidas.alturaFila,
                leading: Icon(
                  parcela.parcelaId == vm.parcela?.parcelaId
                      ? Symbols.radio_button_checked
                      : Symbols.radio_button_unchecked,
                  color: Colores.primario,
                ),
                title: Text(parcela.nombre, style: Tipografia.cuerpoGrande),
                subtitle: Text(Textos.municipio(parcela.municipio)),
                onTap: () {
                  Navigator.of(hoja).pop();
                  vm.elegirParcela(parcela);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportesVm>();
    final parcela = vm.parcela;
    final resumen = vm.resumen;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: parcela == null ? null : 72,
        title: parcela == null
            ? const Text(Textos.resumen)
            : Semantics(
                button: vm.parcelas.length > 1,
                label: '${Textos.resumen}, ${parcela.nombre}',
                excludeSemantics: true,
                child: InkWell(
                  onTap: vm.parcelas.length > 1
                      ? () => _elegirParcela(context, vm)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Textos.resumen,
                        style: Tipografia.titulo.copyWith(color: Colors.white),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              parcela.nombre,
                              overflow: TextOverflow.ellipsis,
                              style: Tipografia.cuerpo.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                          if (vm.parcelas.length > 1)
                            Icon(
                              Symbols.arrow_drop_down,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        actions: [
          if (resumen != null)
            TextButton(
              onPressed: () => mostrarExportarHoja(context, vm),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.ios_share, size: 26),
                  Text(Textos.enviar, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
      body: vm.sinParcelas
          ? const EstadoVacio(
              icono: Symbols.bar_chart,
              titulo: Textos.sinParcelasReporte,
              detalle: Textos.sinParcelasReporteDetalle,
            )
          : ListView(
              padding: const EdgeInsets.all(Medidas.margenPantalla),
              children: [
                SelectorPeriodo(vm: vm),
                const SizedBox(height: Medidas.separacionTarjetas),
                if (vm.cargando || resumen == null)
                  const _Cargando()
                else ...[
                  _Indicadores(resumen: resumen),
                  const SizedBox(height: Medidas.separacionTarjetas),
                  if (!resumen.hayDatos)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        Textos.sinDatosPeriodo,
                        textAlign: TextAlign.center,
                        style: Tipografia.cuerpoGrande.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else ...[
                    TarjetaGrafica(
                      titulo: Textos.temperaturaDelPeriodo(
                        resumen.periodo.cantidadDias,
                      ),
                      frase: Textos.fraseTemperatura(
                        resumen.nocheMasFria?.dia,
                        resumen.nocheMasFria == null
                            ? null
                            : ResumenPeriodo.minimaDe(resumen.nocheMasFria!),
                        resumen.diaMasCaliente?.dia,
                        resumen.diaMasCaliente == null
                            ? null
                            : ResumenPeriodo.maximaDe(resumen.diaMasCaliente!),
                      ),
                      grafica: GraficaTemperatura(dias: resumen.dias),
                      leyenda: const LeyendaTemperatura(),
                    ),
                    const SizedBox(height: Medidas.separacionTarjetas),
                    TarjetaGrafica(
                      titulo: Textos.lluviaPorDia,
                      frase: Textos.fraseLluvia(
                        resumen.diaMasLluvioso?.dia,
                        resumen.diaMasLluvioso?.precipitacion,
                      ),
                      grafica: GraficaLluvia(dias: resumen.dias),
                    ),
                  ],
                  const SizedBox(height: Medidas.separacionTarjetas),
                  BotonSecundario(
                    texto: Textos.verDiaPorDia,
                    icono: Symbols.calendar_month,
                    alPresionar: () => context.push(
                      Rutas.historialParcela(resumen.parcela.parcelaId),
                    ),
                  ),
                  const SizedBox(height: Medidas.espacioM),
                  const AvisoApoyo(),
                ],
              ],
            ),
    );
  }
}

/// 7 días · 30 días · Elegir (calendario). También lo usa la hoja 27.
class SelectorPeriodo extends StatelessWidget {
  const SelectorPeriodo({super.key, required this.vm});

  final ReportesVm vm;

  Future<void> _elegirFechas(BuildContext context) async {
    final hoy = vm.ahora;
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(hoy.year - 2),
      lastDate: DateTime(hoy.year, hoy.month, hoy.day),
      initialDateRange: DateTimeRange(
        start: vm.periodo.desde,
        end: vm.periodo.hasta,
      ),
      helpText: Textos.elegirPeriodo,
    );
    if (rango == null) return;
    vm.elegirPeriodo(
      OpcionPeriodo.elegido,
      elegido: Periodo(
        desde: DateTime.utc(
          rango.start.year,
          rango.start.month,
          rango.start.day,
        ),
        hasta: DateTime.utc(rango.end.year, rango.end.month, rango.end.day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ChipSeleccion(
                texto: Textos.sieteDias,
                elegido: vm.opcion == OpcionPeriodo.siete,
                alTocar: () => vm.elegirPeriodo(OpcionPeriodo.siete),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChipSeleccion(
                texto: Textos.treintaDias,
                elegido: vm.opcion == OpcionPeriodo.treinta,
                alTocar: () => vm.elegirPeriodo(OpcionPeriodo.treinta),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChipSeleccion(
                texto: Textos.elegir,
                elegido: vm.opcion == OpcionPeriodo.elegido,
                alTocar: () => _elegirFechas(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          Textos.periodoEnPalabras(vm.periodo.desde, vm.periodo.hasta),
          style: Tipografia.cuerpo.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Indicadores extends StatelessWidget {
  const _Indicadores({required this.resumen});

  final ResumenPeriodo resumen;

  @override
  Widget build(BuildContext context) {
    final claro = Theme.of(context).brightness == Brightness.light;
    final cielo = claro ? Colores.acentoCielo : Colores.acentoCieloTemaOscuro;
    final fria = resumen.nocheMasFria;
    final peligro = resumen.avisosPeligro;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Indicador(
                icono: Symbols.rainy,
                colorIcono: cielo,
                valor: '${resumen.diasConLluvia}',
                etiqueta: Textos.diasConLluvia(resumen.diasConLluvia),
              ),
            ),
            const SizedBox(width: Medidas.separacionTarjetas),
            Expanded(
              child: _Indicador(
                icono: Symbols.ac_unit,
                colorIcono: cielo,
                valor: fria == null
                    ? '—'
                    : '${ResumenPeriodo.minimaDe(fria)!.round()} °C',
                etiqueta: Textos.nocheMasFria,
              ),
            ),
          ],
        ),
        const SizedBox(height: Medidas.separacionTarjetas),
        Row(
          children: [
            Expanded(
              child: _Indicador(
                icono: Symbols.water_drop,
                colorIcono: cielo,
                valor: '${resumen.lluviaTotal.round()} mm',
                etiqueta: Textos.llovioEnTotal,
              ),
            ),
            const SizedBox(width: Medidas.separacionTarjetas),
            Expanded(
              child: _Indicador(
                icono: peligro == 0 ? Symbols.check_circle : Symbols.error,
                valor: '$peligro',
                etiqueta: peligro == 0
                    ? Textos.sinPeligro
                    : Textos.avisosDePeligro(peligro),
                nivel: peligro == 0
                    ? NivelSeveridad.informativa
                    : NivelSeveridad.critica,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mosaico de un indicador; el de avisos lleva el color del semáforo.
class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.colorIcono,
    this.nivel,
  });

  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color? colorIcono;
  final NivelSeveridad? nivel;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final tono = nivel == null ? null : ColoresSemaforo.of(context).de(nivel!);
    return Semantics(
      label: '$valor $etiqueta',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 130),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: tono?.fondo ?? esquema.surface,
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          border: Border.all(color: tono?.borde ?? esquema.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 30, color: tono?.icono ?? colorIcono),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                valor,
                style: Tipografia.datoGrande.copyWith(
                  color: tono?.texto ?? esquema.onSurface,
                ),
              ),
            ),
            Text(
              etiqueta,
              style: Tipografia.cuerpo.copyWith(
                color: tono?.texto ?? esquema.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      EsqueletoCarga(alto: 130),
      SizedBox(height: Medidas.separacionTarjetas),
      EsqueletoCarga(alto: 130),
      SizedBox(height: Medidas.separacionTarjetas),
      EsqueletoCarga(alto: 240),
    ],
  );
}
