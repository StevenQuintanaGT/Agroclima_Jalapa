import 'package:agroclima_jalapa/modelos/usuario.dart';
import 'package:agroclima_jalapa/repositorios/firestore_usuario_repositorio.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreUsuarioRepositorio repositorio;

  setUp(() async {
    db = FakeFirebaseFirestore();
    repositorio = FirestoreUsuarioRepositorio(db: db);
    await repositorio.crearPerfil(
      const Usuario(
        uid: 'ana',
        nombre: 'Ana López',
        correo: 'ana@correo.com',
        tokensFcm: ['tel-1', 'tel-2'],
      ),
    );
  });

  test('el perfil en vivo trae los ajustes guardados', () async {
    await repositorio.guardarAjustes('ana', unidadTemperatura: 'F');
    final perfil = await repositorio.observarPerfil('ana').first;
    expect(perfil!.fahrenheit, isTrue);
    expect(perfil.hectareas, isFalse);
    expect(await repositorio.observarPerfil('nadie').first, isNull);
  });

  test('guardar un ajuste no toca los demás ni los tokens', () async {
    await repositorio.guardarAjustes('ana', temaOscuro: true);
    await repositorio.guardarAjustes('ana', unidadArea: 'hectarea');
    final datos = (await db.doc('usuarios/ana').get()).data()!;
    expect(datos['temaOscuro'], isTrue);
    expect(datos['unidadArea'], 'hectarea');
    expect(datos['unidadTemperatura'], 'C');
    expect(datos['ahorroDatos'], isFalse);
    expect(datos['tokensFcm'], ['tel-1', 'tel-2']);
  });

  test('cambiar mis datos: nombre y teléfono, el correo no', () async {
    await repositorio.guardarDatos(
      'ana',
      nombre: 'Ana María López',
      telefono: '+50255123456',
    );
    final datos = (await db.doc('usuarios/ana').get()).data()!;
    expect(datos['nombre'], 'Ana María López');
    expect(datos['telefono'], '+50255123456');
    expect(datos['correo'], 'ana@correo.com');
  });

  test('pedir eliminar: marca la fecha y deja sin avisos (D-55)', () async {
    await repositorio.solicitarEliminacion('ana');
    final datos = (await db.doc('usuarios/ana').get()).data()!;
    expect(datos['eliminacionSolicitada'], isNotNull);
    expect(datos['tokensFcm'], isEmpty);
    final perfil = await repositorio.obtenerPerfil('ana');
    expect(perfil!.eliminacionSolicitada, isNotNull);
  });

  test('iniciales para el círculo del perfil', () {
    Usuario de(String nombre) => Usuario(uid: 'x', nombre: nombre, correo: '');
    expect(de('Juan López').iniciales, 'JL');
    expect(de('  juan  carlos  lópez ').iniciales, 'JL');
    expect(de('Ana').iniciales, 'A');
    expect(de('').iniciales, '?');
  });
}
