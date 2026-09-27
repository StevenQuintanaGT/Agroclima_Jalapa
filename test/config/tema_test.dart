import 'dart:math' as math;

import 'package:agroclima_jalapa/config/tema/colores.dart';
import 'package:agroclima_jalapa/config/tema/colores_semaforo.dart';
import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Relación de contraste WCAG 2.x entre dos colores opacos.
double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('Contraste AA (≥ 4.5:1) del semáforo', () {
    for (final (nombre, semaforo) in [
      ('claro', ColoresSemaforo.claro),
      ('oscuro', ColoresSemaforo.oscuro),
    ]) {
      for (final nivel in NivelSeveridad.values) {
        test('$nombre · ${nivel.valor}: texto e ícono sobre su fondo', () {
          final tono = semaforo.de(nivel);
          expect(contraste(tono.texto, tono.fondo), greaterThanOrEqualTo(4.5));
          expect(contraste(tono.icono, tono.fondo), greaterThanOrEqualTo(4.5));
        });
      }
    }
  });

  test('texto principal y secundario cumplen AA en ambos temas', () {
    expect(contraste(Colores.texto, Colores.fondo), greaterThanOrEqualTo(4.5));
    expect(
      contraste(Colores.textoTenue, Colores.superficie),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contraste(Colores.textoOscuro, Colores.fondoOscuro),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contraste(Colores.textoTenueOscuro, Colores.superficieOscura),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('el botón principal cumple AA (blanco sobre verde)', () {
    expect(
      contraste(Colors.white, Colores.primario),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('cada tema trae su semáforo', () {
    expect(
      TemaApp.claro.extension<ColoresSemaforo>(),
      same(ColoresSemaforo.claro),
    );
    expect(
      TemaApp.oscuro.extension<ColoresSemaforo>(),
      same(ColoresSemaforo.oscuro),
    );
  });

  test('NivelSeveridad usa los valores de Firestore', () {
    expect(NivelSeveridad.values.map((n) => n.valor), [
      'informativa',
      'preventiva',
      'critica',
    ]);
    expect(NivelSeveridad.desdeValor('critica'), NivelSeveridad.critica);
    expect(NivelSeveridad.desdeValor('otra'), isNull);
  });
}
