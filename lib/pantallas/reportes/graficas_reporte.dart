import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/registro_dia.dart';
import '../../servicios/reportes_servicio.dart';

/// Tarjeta de una gráfica con su título y la frase que la explica (plans/05):
/// la frase dice lo importante, la gráfica es apoyo.
class TarjetaGrafica extends StatelessWidget {
  const TarjetaGrafica({
    super.key,
    required this.titulo,
    required this.frase,
    required this.grafica,
    this.leyenda,
  });

  final String titulo;
  final String frase;
  final Widget grafica;
  final Widget? leyenda;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esquema.surface,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        border: Border.all(color: esquema.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              titulo,
              style: Tipografia.subtitulo.copyWith(
                fontWeight: FontWeight.w700,
                color: esquema.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            frase,
            style: Tipografia.cuerpoGrande.copyWith(
              color: esquema.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ExcludeSemantics(child: SizedBox(height: 170, child: grafica)),
          if (leyenda != null) ...[const SizedBox(height: 12), leyenda!],
        ],
      ),
    );
  }
}

/// Colores de las dos líneas (diseño 25): ámbar lo más caliente, azul lo más frío.
({Color caliente, Color frio}) coloresTemperatura(BuildContext context) {
  final claro = Theme.of(context).brightness == Brightness.light;
  return (
    caliente: claro ? Colores.precaucionBorde : Colores.precaucionTextoOscuro,
    frio: claro ? Colores.acentoCielo : Colores.acentoCieloTemaOscuro,
  );
}

/// Etiquetas del eje de días: todas en una semana; cada 5 días en un mes.
SideTitles _ejeDias(BuildContext context, List<RegistroDia> dias) {
  final esquema = Theme.of(context).colorScheme;
  final cada = dias.length <= 10 ? 1 : 5;
  return SideTitles(
    showTitles: true,
    interval: 1,
    reservedSize: 26,
    getTitlesWidget: (valor, meta) {
      final i = valor.toInt();
      if (valor != i || i < 0 || i >= dias.length || i % cada != 0) {
        return const SizedBox.shrink();
      }
      return SideTitleWidget(
        meta: meta,
        fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
        child: Text(
          '${dias[i].dia.day}',
          style: Tipografia.cuerpoChico.copyWith(
            color: esquema.onSurfaceVariant,
          ),
        ),
      );
    },
  );
}

/// Máxima y mínima de cada día; los días sin dato dejan un hueco.
class GraficaTemperatura extends StatelessWidget {
  const GraficaTemperatura({super.key, required this.dias});

  final List<RegistroDia> dias;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final colores = coloresTemperatura(context);
    // Con mínimas y máximas del ciclo (D-53) se grafican solo esas: un día
    // con una sola temperatura registrada juntaría las dos líneas. Si ningún
    // día las tiene (datos de antes), se usa la registrada.
    final hayExtremos = dias.any(
      (d) => d.temperaturaMinima != null && d.temperaturaMaxima != null,
    );
    double? minima(RegistroDia d) =>
        hayExtremos ? d.temperaturaMinima : ResumenPeriodo.minimaDe(d);
    double? maxima(RegistroDia d) =>
        hayExtremos ? d.temperaturaMaxima : ResumenPeriodo.maximaDe(d);
    final valores = [
      for (final d in dias) ...[?minima(d), ?maxima(d)],
    ];
    if (valores.isEmpty) return const SizedBox.shrink();
    final minimo = valores.reduce((a, b) => a < b ? a : b);
    final maximo = valores.reduce((a, b) => a > b ? a : b);

    LineChartBarData linea(double? Function(RegistroDia) valor, Color color) =>
        LineChartBarData(
          spots: [
            for (var i = 0; i < dias.length; i++)
              valor(dias[i]) == null
                  ? FlSpot.nullSpot
                  : FlSpot(i.toDouble(), valor(dias[i])!),
          ],
          color: color,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(show: dias.length <= 10),
        );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (dias.length - 1).toDouble().clamp(1, double.infinity),
        minY: minimo - 2,
        maxY: maximo + 2,
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
          bottomTitles: AxisTitles(sideTitles: _ejeDias(context, dias)),
        ),
        lineBarsData: [
          linea(maxima, colores.caliente),
          linea(minima, colores.frio),
        ],
      ),
    );
  }
}

/// Leyenda "Más caliente · Más frío".
class LeyendaTemperatura extends StatelessWidget {
  const LeyendaTemperatura({super.key});

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final colores = coloresTemperatura(context);
    Widget item(Color color, String texto) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: Tipografia.cuerpo.copyWith(color: esquema.onSurfaceVariant),
        ),
      ],
    );
    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: [
        item(colores.caliente, Textos.masCaliente),
        item(colores.frio, Textos.masFrio),
      ],
    );
  }
}

/// Barras de la lluvia de cada día (mm).
class GraficaLluvia extends StatelessWidget {
  const GraficaLluvia({super.key, required this.dias});

  final List<RegistroDia> dias;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final claro = Theme.of(context).brightness == Brightness.light;
    final color = claro ? Colores.acentoCielo : Colores.acentoCieloTemaOscuro;
    final maximo = dias
        .map((d) => d.precipitacion ?? 0)
        .fold<double>(0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maximo < 5 ? 5 : maximo * 1.15,
        barTouchData: BarTouchData(enabled: false),
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
          bottomTitles: AxisTitles(sideTitles: _ejeDias(context, dias)),
        ),
        barGroups: [
          for (var i = 0; i < dias.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dias[i].precipitacion ?? 0,
                  color: color,
                  width: dias.length <= 10 ? 22 : 6,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
