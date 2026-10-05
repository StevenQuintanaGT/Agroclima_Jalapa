import 'dart:convert';
import 'dart:io';

import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/repositorios/firestore_umbrales_repositorio.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carga la misma semilla que usa el ciclo (functions/seed/umbrales.json).
Future<FakeFirebaseFirestore> _conSemilla() async {
  final db = FakeFirebaseFirestore();
  final semilla = jsonDecode(
    File('functions/seed/umbrales.json').readAsStringSync(),
  ) as List<dynamic>;
  for (final umbral in semilla.cast<Map<String, dynamic>>()) {
    await db.doc('umbrales/${umbral['umbralId']}').set(umbral);
  }
  return db;
}

void main() {
  test('lee los 24 umbrales vigentes de la semilla', () async {
    final repo = FirestoreUmbralesRepositorio(db: await _conSemilla());
    final umbrales = await repo.vigentes();
    expect(umbrales, hasLength(24));
    final helada = umbrales.firstWhere(
      (u) => u.umbralId == 'tmin_general_critica',
    );
    expect(helada.tipoRiesgo, TipoRiesgo.temperaturaBaja);
    expect(helada.nivel, NivelSeveridad.critica);
    expect(helada.valor, 0);
    expect(helada.cultivo, isNull);
  });

  test('aplicaA da lo mismo que el ciclo (UMBRALES.md §3)', () async {
    final umbrales = await FirestoreUmbralesRepositorio(db: await _conSemilla())
        .vigentes();
    final generales = umbrales.where((u) => u.cultivo == null).length;
    int cuantos(Cultivo? cultivo, Etapa? etapa) =>
        umbrales.where((u) => u.aplicaA(cultivo, etapa)).length;
    expect(cuantos(null, null), generales);
    expect(cuantos(Cultivo.hortalizas, Etapa.floracion), generales);
    expect(cuantos(Cultivo.cafe, Etapa.cosecha), generales + 4);
    expect(cuantos(Cultivo.maiz, Etapa.floracion), generales + 3);
  });

  test('ignora los no vigentes y los que no se entienden', () async {
    final db = FakeFirebaseFirestore();
    await db.doc('umbrales/apagado').set({
      'tipoRiesgo': 'sequia',
      'variable': 'diasSecos',
      'operador': 'mayor',
      'valor': 15,
      'nivel': 'critica',
      'vigente': false,
    });
    await db.doc('umbrales/raro').set({
      'tipoRiesgo': 'tornado',
      'nivel': 'critica',
      'valor': 1,
      'vigente': true,
    });
    expect(await FirestoreUmbralesRepositorio(db: db).vigentes(), isEmpty);
  });
}
