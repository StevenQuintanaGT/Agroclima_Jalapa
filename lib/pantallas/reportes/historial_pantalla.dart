import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/boton_secundario.dart';
import '../../componentes/chip_seleccion.dart';
import '../../componentes/esqueleto_carga.dart';
import '../../componentes/estado_vacio.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/colores_semaforo.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../servicios/historial_servicio.dart';
import 'historial_vm.dart';

/// Día por día (pantalla 26, HU-13): una fila por día con fecha, cómo
/// estuvo la lluvia, avisos y máxima/mínima. Lista y no tabla: en 360 dp una
/// tabla obliga a desplazar de lado.
class HistorialPantalla extends StatelessWidget {
  const HistorialPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistorialVm>();
    final dias = vm.dias;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: vm.parcela == null ? null : 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Textos.diaPorDia,
              style: Tipografia.titulo.copyWith(color: Colors.white),
            ),
            if (vm.parcela != null)
              Text(
                vm.parcela!.nombre,
                style: Tipografia.cuerpo.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
          ],
        ),
      ),
      body: vm.cargando
          ? const _Cargando()
          : !vm.hayDias
          ? const EstadoVacio(
              icono: Symbols.calendar_month,
              titulo: Textos.sinDias,
              detalle: Textos.sinDiasDetalle,
            )
          : ListView(
              padding: const EdgeInsets.all(Medidas.margenPantalla),
              children: [
                _Filtros(filtro: vm.filtro, alElegir: vm.elegirFiltro),
                const SizedBox(height: Medidas.separacionTarjetas),
                if (dias.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      vm.filtro == FiltroHistorial.conLluvia
                          ? Textos.sinDiasConLluvia
                          : Textos.sinDiasConAviso,
                      textAlign: TextAlign.center,
                      style: Tipografia.cuerpoGrande.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (final dia in dias) ...[
                  _FilaDia(dia: dia, esHoy: dia.registro.fecha == vm.hoy),
                  const SizedBox(height: Medidas.separacionTarjetas),
                ],
                if (vm.hayMas)
                  BotonSecundario(
                    texto: vm.cargandoMas
                        ? Textos.buscandoDias
                        : Textos.verDiasAnteriores,
                    icono: Symbols.history,
                    alPresionar: vm.cargandoMas ? null : vm.verMas,
                  ),
              ],
            ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.filtro, required this.alElegir});

  final FiltroHistorial filtro;
  final void Function(FiltroHistorial filtro) alElegir;

  @override
  Widget build(BuildContext context) {
    const opciones = [
      (FiltroHistorial.todo, Textos.filtroTodo),
      (FiltroHistorial.conLluvia, Textos.filtroConLluvia),
      (FiltroHistorial.conAviso, Textos.filtroConAviso),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (opcion, texto) in opciones) ...[
            if (opcion != FiltroHistorial.todo) const SizedBox(width: 8),
            ChipSeleccion(
              texto: texto,
              elegido: filtro == opcion,
              alTocar: () => alElegir(opcion),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaDia extends StatelessWidget {
  const _FilaDia({required this.dia, required this.esHoy});

  final DiaHistorial dia;
  final bool esHoy;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final claro = Theme.of(context).brightness == Brightness.light;
    final registro = dia.registro;
    final fecha = registro.dia;
    final resumen = Textos.resumenLluviaDia(registro.precipitacion);
    final detalle = Textos.detalleDia(registro.precipitacion, dia.avisos);
    final franja = dia.nivelAviso == null
        ? null
        : ColoresSemaforo.of(context).de(dia.nivelAviso!).borde;
    final maxima = registro.temperaturaMaxima;
    final minima = registro.temperaturaMinima;
    final (icono, colorIcono) = switch (registro.precipitacion) {
      null => (Symbols.remove, esquema.onSurfaceVariant),
      < 1 => (Symbols.wb_sunny, Colores.sol),
      _ => (
        Symbols.rainy,
        claro ? Colores.acentoCielo : Colores.acentoCieloTemaOscuro,
      ),
    };
    final fechaTexto = esHoy
        ? Textos.hoy
        : '${fecha.day} ${Textos.nombreMes(fecha)}';
    return Semantics(
      label: Textos.lecturaDia(fechaTexto, resumen, detalle),
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: esquema.surface,
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          border: Border.all(color: esquema.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (franja != null) Container(width: 10, color: franja),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: esHoy
                            ? Text(
                                Textos.hoy,
                                style: Tipografia.subtitulo.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: esquema.onSurface,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${fecha.day}',
                                    style: Tipografia.titulo.copyWith(
                                      color: esquema.onSurface,
                                    ),
                                  ),
                                  Text(
                                    Textos.nombreMes(fecha),
                                    style: Tipografia.cuerpo.copyWith(
                                      color: esquema.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      Icon(icono, size: 34, color: colorIcono),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resumen,
                              style: Tipografia.cuerpoGrande.copyWith(
                                color: esquema.onSurface,
                              ),
                            ),
                            Text(
                              detalle,
                              style: Tipografia.cuerpo.copyWith(
                                color: esquema.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Máxima/mínima; si el día no las tiene, la registrada.
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: maxima != null && minima != null
                            ? [
                                Text(
                                  Textos.grados(maxima),
                                  style: Tipografia.subtitulo.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: esquema.onSurface,
                                  ),
                                ),
                                Text(
                                  Textos.grados(minima),
                                  style: Tipografia.subtitulo.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: esquema.onSurfaceVariant,
                                  ),
                                ),
                              ]
                            : [
                                Text(
                                  registro.temperatura == null
                                      ? '—'
                                      : Textos.grados(registro.temperatura!),
                                  style: Tipografia.subtitulo.copyWith(
                                    color: esquema.onSurface,
                                  ),
                                ),
                              ],
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

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(Medidas.margenPantalla),
    children: [
      for (var i = 0; i < 4; i++) ...[
        const EsqueletoCarga(alto: 84),
        const SizedBox(height: Medidas.separacionTarjetas),
      ],
    ],
  );
}
