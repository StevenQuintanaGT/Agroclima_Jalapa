import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/aviso_apoyo.dart';
import '../../componentes/esqueleto_carga.dart';
import '../../componentes/estado_vacio.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/franja_pronostico.dart';
import '../../modelos/resumen_dia.dart';
import '../../utilidades/fechas.dart';
import 'detalle_pronostico_vm.dart';

/// Pantalla 19 · Pronóstico detallado (HU-08). Cada gráfica lleva una frase
/// que la interpreta, para que no haga falta saber leer un eje.
class DetallePronosticoPantalla extends StatelessWidget {
  const DetallePronosticoPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetallePronosticoVm>();
    final dia = vm.dia;
    return Scaffold(
      appBar: AppBar(title: const Text(Textos.pronosticoDetallado)),
      body: SafeArea(
        child: vm.cargando
            ? ListView(
                padding: const EdgeInsets.all(Medidas.margenPantalla),
                children: const [
                  EsqueletoCarga(alto: 64, radio: Medidas.radioPildora),
                  SizedBox(height: Medidas.separacionTarjetas),
                  EsqueletoCarga(alto: 240, radio: Medidas.radioTarjeta),
                ],
              )
            : dia == null
            ? const EstadoVacio(
                icono: Symbols.cloud_off,
                titulo: Textos.sinDatosClimaTitulo,
                detalle: Textos.errorServicioDetalle,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.margenPantalla,
                  Medidas.margenPantalla,
                  Medidas.margenPantalla,
                  Medidas.espacioM,
                ),
                children: [
                  _SelectorDias(vm: vm),
                  const SizedBox(height: Medidas.espacioS),
                  _Tarjeta(
                    child: _Temperatura(vm: vm, dia: dia),
                  ),
                  const SizedBox(height: Medidas.separacionTarjetas),
                  _Tarjeta(
                    child: _Lluvia(dia: dia, esHoy: vm.esHoy),
                  ),
                  const SizedBox(height: Medidas.separacionTarjetas),
                  _Tarjeta(
                    child: _Resumen(vm: vm, dia: dia),
                  ),
                  const SizedBox(height: Medidas.espacioS),
                  const AvisoApoyo(),
                ],
              ),
      ),
    );
  }
}

class _SelectorDias extends StatelessWidget {
  const _SelectorDias({required this.vm});

  final DetallePronosticoVm vm;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final dias = vm.dias;
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dias.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final dia = dias[i];
          final elegido = dia.fecha == vm.dia?.fecha;
          final segunda = dia.esHoy ? Textos.hoy : Textos.diaCorto(dia.dia);
          return Semantics(
            selected: elegido,
            button: true,
            child: Material(
              color: elegido ? Colores.primario : esquema.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Medidas.radioPildora),
                side: BorderSide(
                  color: elegido ? Colores.primario : Colores.bordeFuerte,
                  width: 1.5,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(Medidas.radioPildora),
                onTap: () => vm.elegir(dia),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        Textos.nombreDia(dia.dia),
                        style: Tipografia.etiqueta.copyWith(
                          fontSize: 17,
                          color: elegido ? Colors.white : esquema.onSurface,
                        ),
                      ),
                      Text(
                        segunda,
                        style: Tipografia.cuerpoChico.copyWith(
                          color: elegido
                              ? Colors.white.withValues(alpha: 0.9)
                              : esquema.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Medidas.espacioS),
      decoration: BoxDecoration(
        color: esquema.surface,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        border: Border.all(color: esquema.outlineVariant),
      ),
      child: child,
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.titulo, required this.frase});

  final String titulo;
  final String frase;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Tipografia.subtitulo.copyWith(
            fontSize: 20,
            color: esquema.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          frase,
          style: Tipografia.cuerpo.copyWith(color: esquema.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Hora del día en Guatemala (0 a 21) de una franja, para el eje.
double _horaDelDia(FranjaPronostico franja) =>
    Fechas.aHoraGuatemala(franja.fechaHora).hour.toDouble();

class _Temperatura extends StatelessWidget {
  const _Temperatura({required this.vm, required this.dia});

  final DetallePronosticoVm vm;
  final ResumenDia dia;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final claro = Theme.of(context).brightness == Brightness.light;
    final linea = claro ? Colores.precaucionBorde : Colores.solTemaOscuro;
    final frio = claro ? Colores.acentoCielo : Colores.acentoCieloTemaOscuro;
    final franjas = dia.franjas;
    final masFria = vm.masFria;
    final masCaliente = vm.masCaliente;
    final frase = masFria == null
        ? '${Textos.maxima} ${Textos.grados(dia.temperaturaMaxima)} · '
              '${Textos.minima} ${Textos.grados(dia.temperaturaMinima)}'
        : Textos.loMasFrio(Fechas.aHoraGuatemala(masFria.fechaHora));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Encabezado(titulo: Textos.comoCambiaTemperatura, frase: frase),
        if (masFria != null && masCaliente != null) ...[
          const SizedBox(height: Medidas.espacioXs),
          Row(
            children: [
              Text(
                '${Textos.maxima} ${Textos.grados(masCaliente.temperatura)}',
                style: Tipografia.etiqueta.copyWith(color: linea),
              ),
              const SizedBox(width: Medidas.espacioS),
              Text(
                '${Textos.minima} ${Textos.grados(masFria.temperatura)}',
                style: Tipografia.etiqueta.copyWith(color: frio),
              ),
            ],
          ),
        ],
        if (franjas.length >= 2) ...[
          const SizedBox(height: Medidas.espacioS),
          ExcludeSemantics(
            child: SizedBox(
              height: 170,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 21,
                  minY:
                      franjas
                          .map((f) => f.temperatura)
                          .reduce((a, b) => a < b ? a : b) -
                      2,
                  maxY:
                      franjas
                          .map((f) => f.temperatura)
                          .reduce((a, b) => a > b ? a : b) +
                      2,
                  lineTouchData: const LineTouchData(enabled: false),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: esquema.outlineVariant, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 6,
                        reservedSize: 28,
                        // Solo 12 a.m., 6 a.m., 12 p.m. y 6 p.m., dentro del borde.
                        getTitlesWidget: (valor, meta) => valor % 6 != 0
                            ? const SizedBox.shrink()
                            : SideTitleWidget(
                                meta: meta,
                                fitInside: SideTitleFitInsideData.fromTitleMeta(
                                  meta,
                                ),
                                child: Text(
                                  Textos.horaSinMinutos(
                                    DateTime.utc(2000, 1, 1, valor.toInt()),
                                  ),
                                  style: Tipografia.cuerpoChico.copyWith(
                                    color: esquema.onSurfaceVariant,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (final f in franjas)
                          FlSpot(_horaDelDia(f), f.temperatura),
                      ],
                      color: linea,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        checkToShowDot: (punto, _) =>
                            punto.x == _horaDelDia(masFria!) ||
                            punto.x == _horaDelDia(masCaliente!),
                        getDotPainter: (punto, _, _, _) => FlDotCirclePainter(
                          radius: 6,
                          color: punto.x == _horaDelDia(masFria!)
                              ? frio
                              : linea,
                          strokeWidth: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Lluvia extends StatelessWidget {
  const _Lluvia({required this.dia, required this.esHoy});

  final ResumenDia dia;
  final bool esHoy;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final claro = Theme.of(context).brightness == Brightness.light;
    final azul = claro ? Colores.acentoCielo : Colores.acentoCieloTemaOscuro;
    // 8 franjas de 3 h: 12 a.m., 3 a.m., … 9 p.m. (hora de Guatemala).
    final porHora = {
      for (final f in dia.franjas) _horaDelDia(f).toInt(): f.lluvia3h,
    };
    final maximo = porHora.values.fold<double>(0, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Encabezado(
          titulo: Textos.cuantaLluvia,
          frase: Textos.totalEsperado(
            esHoy: esHoy,
            mm: dia.acumuladoDia,
            mmHora: dia.precipitacionHora,
          ),
        ),
        if (dia.franjas.isNotEmpty) ...[
          const SizedBox(height: Medidas.espacioS),
          ExcludeSemantics(
            child: SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var hora = 0; hora < 24; hora += 3) ...[
                    if (hora > 0) const SizedBox(width: 6),
                    Expanded(
                      child: _Barra(
                        valor: porHora[hora],
                        maximo: maximo,
                        color: azul,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final parte in [
                Textos.madrugada,
                Textos.manana,
                Textos.tarde,
                Textos.noche,
              ])
                Expanded(
                  child: Text(
                    parte,
                    textAlign: TextAlign.center,
                    style: Tipografia.cuerpoChico.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.valor,
    required this.maximo,
    required this.color,
  });

  /// mm en la franja; `null` si la franja ya pasó o no hay dato.
  final double? valor;
  final double maximo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final mm = valor ?? 0;
    final proporcion = maximo <= 0 ? 0.0 : mm / maximo;
    return Container(
      height: 4 + 120 * proporcion,
      decoration: BoxDecoration(
        // Más llena cuanto más llueve.
        color: valor == null
            ? Colors.transparent
            : color.withValues(alpha: 0.3 + 0.7 * proporcion),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.vm, required this.dia});

  final DetallePronosticoVm vm;
  final ResumenDia dia;

  @override
  Widget build(BuildContext context) {
    final claro = Theme.of(context).brightness == Brightness.light;
    final cielo = claro ? Colores.acentoCielo : Colores.acentoCieloTemaOscuro;
    final sol = claro ? Colores.precaucionIcono : Colores.solTemaOscuro;
    final actual = vm.solDeHoy;
    final salida = actual?.salidaSol;
    final puesta = actual?.puestaSol;
    return Column(
      children: [
        _FilaResumen(
          icono: Symbols.air,
          color: cielo,
          etiqueta: Textos.vientoMasFuerte,
          valor: Textos.kmPorHora(dia.velocidadViento),
        ),
        _FilaResumen(
          icono: Symbols.humidity_percentage,
          color: cielo,
          etiqueta: Textos.humedadDelAire,
          valor: '${dia.humedadRelativa.round()}%',
        ),
        if (salida != null && puesta != null)
          _FilaResumen(
            icono: Symbols.wb_twilight,
            color: sol,
            etiqueta: Textos.saleYSePone,
            valor:
                '${Textos.horaCorta(Fechas.aHoraGuatemala(salida))} · '
                '${Textos.horaCorta(Fechas.aHoraGuatemala(puesta))}',
          ),
      ],
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen({
    required this.icono,
    required this.color,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final Color color;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Semantics(
      label: '$etiqueta: $valor',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icono, size: 28, color: color),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: Text(
                etiqueta,
                style: Tipografia.cuerpoGrande.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: Medidas.espacioXs),
            Flexible(
              flex: 2,
              child: Text(
                valor,
                textAlign: TextAlign.end,
                style: Tipografia.subtitulo.copyWith(color: esquema.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
