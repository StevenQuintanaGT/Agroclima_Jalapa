import 'package:agroclima_jalapa/modelos/encuesta.dart';
import 'package:agroclima_jalapa/modelos/respuestas_encuesta.dart';
import 'package:agroclima_jalapa/repositorios/firestore_encuestas_repositorio.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreEncuestasRepositorio repositorio;

  const respuestas = RespuestasEncuesta(
    p1: 'facil',
    p2: 'todo',
    p3: 'si',
    detalleAviso: 'Helada',
    p4: 'mucho',
    p5: 'no',
    p6: 'sinDanio',
    p7: 'si',
    consentimiento: true,
  );

  setUp(() {
    db = FakeFirebaseFirestore();
    repositorio = FirestoreEncuestasRepositorio(db: db);
  });

  test('sin responder devuelve null', () async {
    expect(await repositorio.obtener('ana'), isNull);
  });

  test('guarda en encuestas/{uid} con los campos del modelo', () async {
    await repositorio.guardar(
      const Encuesta(
        uid: 'ana',
        respuestas: respuestas,
        municipio: 'monjas',
        cultivo: 'maiz',
        versionApp: '1.1.0',
      ),
    );
    final datos = (await db.doc('encuestas/ana').get()).data()!;
    expect(datos['uid'], 'ana');
    expect(datos['p1'], 'facil');
    expect(datos['detalleAviso'], 'Helada');
    expect(datos['consentimiento'], isTrue);
    expect(datos['municipio'], 'monjas');
    expect(datos['cultivo'], 'maiz');
    expect(datos['versionApp'], '1.1.0');
    expect(datos.containsKey('fechaRespuesta'), isTrue);
    expect(datos.containsKey('p8'), isFalse);

    final leida = await repositorio.obtener('ana');
    expect(leida!.respuestas.p6, 'sinDanio');
    expect(leida.respuestas.completa, isTrue);
  });

  test('volver a enviar reemplaza: un detalle quitado no queda', () async {
    const primera = Encuesta(
      uid: 'ana',
      respuestas: respuestas,
      versionApp: '1.1.0',
    );
    await repositorio.guardar(primera);
    await repositorio.guardar(
      Encuesta(
        uid: 'ana',
        respuestas: respuestas.elegir('p3', 'no').limpias(),
        versionApp: '1.1.0',
      ),
    );
    final datos = (await db.doc('encuestas/ana').get()).data()!;
    expect(datos['p3'], 'no');
    expect(datos.containsKey('detalleAviso'), isFalse);
  });
}
