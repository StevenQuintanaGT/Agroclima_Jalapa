import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/repositorios/firestore_alertas_repositorio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreAlertasRepositorio repositorio;

  Map<String, dynamic> alerta(
    String usuario,
    int hora, {
    String nivel = 'critica',
  }) => {
    'usuarioId': usuario,
    'parcelaId': 'joya',
    'tipoRiesgo': 'temperaturaBaja',
    'nivel': nivel,
    'valorEsperado': -1,
    'valorUmbral': 0,
    'mensaje': 'Puede caer helada.',
    'medidaSugerida': 'Proteja el almácigo.',
    'fechaEvento': Timestamp.fromDate(DateTime.utc(2026, 10, 6, 6)),
    'fechaGeneracion': Timestamp.fromDate(DateTime.utc(2026, 10, 5, hora)),
    'leida': false,
    'atendida': false,
    'parcelaNombre': 'La Joya',
    'cultivo': 'cafe',
  };

  setUp(() async {
    db = FakeFirebaseFirestore();
    repositorio = FirestoreAlertasRepositorio(db: db);
    await db.collection('alertas').doc('vieja').set(alerta('ana', 9));
    await db.collection('alertas').doc('nueva').set(alerta('ana', 15));
    await db.collection('alertas').doc('ajena').set(alerta('beto', 12));
    await db
        .collection('alertas')
        .doc('rara')
        .set(alerta('ana', 10, nivel: 'rojo'));
  });

  test(
    'solo las del usuario, la más nueva primero, sin las que no se entienden',
    () async {
      final lista = await repositorio.delUsuario('ana').first;
      expect(lista.map((a) => a.alertaId), ['nueva', 'vieja']);
      final primera = lista.first;
      expect(primera.tipoRiesgo, TipoRiesgo.temperaturaBaja);
      expect(primera.cultivo, Cultivo.cafe);
      expect(primera.fechaEvento, DateTime.utc(2026, 10, 6, 6));
      expect(primera.esHelada, isTrue);
    },
  );

  test('marcar leída y atendida cambia solo esos campos', () async {
    await repositorio.marcarLeida('nueva');
    await repositorio.marcarAtendida('nueva');
    await Future<void>.delayed(Duration.zero);
    final datos = (await db.collection('alertas').doc('nueva').get()).data()!;
    expect(datos['leida'], isTrue);
    expect(datos['atendida'], isTrue);
    expect(datos['nivel'], 'critica');
  });

  test('una alerta borrada se observa como null', () async {
    expect(await repositorio.observar('nada').first, isNull);
    expect((await repositorio.observar('vieja').first)?.alertaId, 'vieja');
  });
}
