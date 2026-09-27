import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// Recuadro con borde punteado: marca de "datos guardados" y marcador de las
/// ilustraciones pendientes del diseño.
class MarcoPunteado extends StatelessWidget {
  const MarcoPunteado({
    super.key,
    required this.child,
    required this.colorBorde,
    this.colorFondo,
    this.radio = 12,
    this.grosor = 2,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final Color colorBorde;
  final Color? colorFondo;
  final double radio;
  final double grosor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PintorPunteado(color: colorBorde, radio: radio, grosor: grosor),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(radio),
        ),
        child: child,
      ),
    );
  }
}

class _PintorPunteado extends CustomPainter {
  _PintorPunteado({
    required this.color,
    required this.radio,
    required this.grosor,
  });

  final Color color;
  final double radio;
  final double grosor;

  static const double _trazo = 6;
  static const double _hueco = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor;
    final medio = grosor / 2;
    final contorno = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            medio,
            medio,
            size.width - grosor,
            size.height - grosor,
          ),
          Radius.circular(radio),
        ),
      );
    for (final PathMetric tramo in contorno.computeMetrics()) {
      var distancia = 0.0;
      while (distancia < tramo.length) {
        canvas.drawPath(
          tramo.extractPath(distancia, distancia + _trazo),
          pincel,
        );
        distancia += _trazo + _hueco;
      }
    }
  }

  @override
  bool shouldRepaint(_PintorPunteado viejo) =>
      viejo.color != color || viejo.radio != radio || viejo.grosor != grosor;
}
