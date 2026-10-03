import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/parcela.dart';
import 'package:agroclima_jalapa/repositorios/auth_repositorio.dart';
import 'package:agroclima_jalapa/repositorios/parcelas_repositorio.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../apoyo/limites.dart';

class _RepoFalso extends Mock implements ParcelasRepositorio {}

class _AuthFalso extends Mock implements AuthRepositorio {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const Parcela(
        usuarioId: '',
        nombre: '',
        municipio: Municipio.jalapa,
        latitud: 0,
        longitud: 0,
        celdaClima: '',
      ),
    );
  });

  late _RepoFalso repo;
  late _AuthFalso auth;
  late ParcelasServicio servicio;

  setUp(() {
    repo = _RepoFalso();
    auth = _AuthFalso();
    servicio = ParcelasServicio(
      repositorio: repo,
      auth: auth,
      validacion: limitesReales(),
    );
    when(() => auth.uidActual).thenReturn('u1');
    when(() => repo.nombres('u1')).thenAnswer((_) async => ['El Guayabal']);
    when(() => repo.crear(any())).thenAnswer(
      (_) async => const ParcelaGuardada(parcelaId: 'p1', pendiente: false),
    );
  });

  test('guarda con el municipio del punto, la celda y el dueño', () async {
    await servicio.registrar(
      nombre: '  La Joya ',
      latitud: cabeceraMonjas.lat,
      longitud: cabeceraMonjas.lon,
      cultivo: Cultivo.cafe,
      etapa: Etapa.floracion,
      area: 2.5,
    );
    final parcela =
        verify(() => repo.crear(captureAny())).captured.single as Parcela;
    expect(parcela.usuarioId, 'u1');
    expect(parcela.nombre, 'La Joya');
    expect(parcela.municipio, Municipio.monjas);
    expect(parcela.celdaClima, '14.50_-89.85');
    expect(parcela.toMap()['cultivo'], 'cafe');
    expect(parcela.toMap()['etapa'], 'floracion');
  });

  test('sin cultivo no guarda etapa (RN-05)', () async {
    await servicio.registrar(
      nombre: 'Potrero',
      latitud: cabeceraJalapa.lat,
      longitud: cabeceraJalapa.lon,
      etapa: Etapa.cosecha,
    );
    final parcela =
        verify(() => repo.crear(captureAny())).captured.single as Parcela;
    expect(parcela.toMap()['cultivo'], '');
    expect(parcela.toMap()['etapa'], '');
  });

  test('fuera de Jalapa no se guarda (VA-01)', () async {
    await expectLater(
      servicio.registrar(
        nombre: 'Lejos',
        latitud: ciudadGuatemala.lat,
        longitud: ciudadGuatemala.lon,
      ),
      throwsA(
        isA<ErrorParcela>().having(
          (e) => e.motivo,
          'motivo',
          MotivoErrorParcela.fueraDeJalapa,
        ),
      ),
    );
    verifyNever(() => repo.crear(any()));
  });

  test(
    'nombre repetido sin importar mayúsculas, tildes ni espacios (VA-02)',
    () async {
      await expectLater(
        servicio.registrar(
          nombre: ' el  guayabál ',
          latitud: cabeceraJalapa.lat,
          longitud: cabeceraJalapa.lon,
        ),
        throwsA(
          isA<ErrorParcela>().having(
            (e) => e.motivo,
            'motivo',
            MotivoErrorParcela.nombreRepetido,
          ),
        ),
      );
    },
  );

  test('sin sesión no se guarda', () async {
    when(() => auth.uidActual).thenReturn(null);
    await expectLater(
      servicio.registrar(
        nombre: 'X',
        latitud: cabeceraJalapa.lat,
        longitud: cabeceraJalapa.lon,
      ),
      throwsA(isA<ErrorParcela>()),
    );
  });

  test('nombreValido: no vacío y hasta 40 letras', () {
    expect(ParcelasServicio.nombreValido('   '), isFalse);
    expect(ParcelasServicio.nombreValido('a' * 40), isTrue);
    expect(ParcelasServicio.nombreValido('a' * 41), isFalse);
  });

  test('Parcela usa los campos y valores de la Tabla 66', () {
    const parcela = Parcela(
      usuarioId: 'u1',
      nombre: 'El Guayabal',
      municipio: Municipio.sanPedroPinula,
      cultivo: Cultivo.frijol,
      etapa: Etapa.llenado,
      latitud: 14.66,
      longitud: -89.84,
      altitud: 1380,
      area: 2.5,
      celdaClima: '14.65_-89.85',
    );
    expect(parcela.toMap(), {
      'usuarioId': 'u1',
      'nombre': 'El Guayabal',
      'municipio': 'sanPedroPinula',
      'cultivo': 'frijol',
      'etapa': 'llenado',
      'altitud': 1380,
      'area': 2.5,
      'unidadArea': 'manzana',
      'celdaClima': '14.65_-89.85',
      'activa': true,
    });
  });

  group('editar y borrar (HU-06)', () {
    final original = Parcela(
      parcelaId: 'p1',
      usuarioId: 'u1',
      nombre: 'El Guayabal',
      municipio: Municipio.jalapa,
      cultivo: Cultivo.maiz,
      etapa: Etapa.floracion,
      latitud: cabeceraJalapa.lat,
      longitud: cabeceraJalapa.lon,
      celdaClima: '14.65_-90.00',
    );

    setUp(() {
      when(() => repo.nombres('u1'))
          .thenAnswer((_) async => ['El Guayabal', 'La Joya']);
      when(() => repo.actualizar(any())).thenAnswer((_) async => false);
    });

    test('conserva id y dueño, y recalcula municipio y celda', () async {
      await servicio.actualizar(
        original: original,
        nombre: 'El Guayabal',
        latitud: cabeceraMonjas.lat,
        longitud: cabeceraMonjas.lon,
        cultivo: Cultivo.frijol,
        etapa: Etapa.cosecha,
      );
      final parcela =
          verify(() => repo.actualizar(captureAny())).captured.single
              as Parcela;
      expect(parcela.parcelaId, 'p1');
      expect(parcela.usuarioId, 'u1');
      expect(parcela.municipio, Municipio.monjas);
      expect(parcela.celdaClima, '14.50_-89.85');
      expect(parcela.cultivo, Cultivo.frijol);
      expect(parcela.etapa, Etapa.cosecha);
    });

    test('el nombre de otra parcela no se puede usar (VA-02)', () async {
      expect(
        () => servicio.actualizar(
          original: original,
          nombre: 'LA JOYA',
          latitud: cabeceraJalapa.lat,
          longitud: cabeceraJalapa.lon,
        ),
        throwsA(
          isA<ErrorParcela>().having(
            (e) => e.motivo,
            'motivo',
            MotivoErrorParcela.nombreRepetido,
          ),
        ),
      );
    });

    test('fuera de Jalapa no se guarda (VA-01)', () async {
      expect(
        () => servicio.actualizar(
          original: original,
          nombre: 'El Guayabal',
          latitud: 14.6349,
          longitud: -90.5069,
        ),
        throwsA(
          isA<ErrorParcela>().having(
            (e) => e.motivo,
            'motivo',
            MotivoErrorParcela.fueraDeJalapa,
          ),
        ),
      );
      verifyNever(() => repo.actualizar(any()));
    });

    test('no deja editar la parcela de otra cuenta (RN-03)', () async {
      when(() => auth.uidActual).thenReturn('otro');
      expect(
        () => servicio.actualizar(
          original: original,
          nombre: 'El Guayabal',
          latitud: cabeceraJalapa.lat,
          longitud: cabeceraJalapa.lon,
        ),
        throwsA(isA<ErrorParcela>()),
      );
    });

    test('borrar pasa el id al repositorio', () async {
      when(() => repo.eliminar('p1')).thenAnswer((_) async => true);
      expect(await servicio.eliminar('p1'), isTrue);
    });

    test('sin sesión la lista está vacía', () async {
      when(() => auth.uidActual).thenReturn(null);
      expect(await servicio.misParcelas().first, isEmpty);
    });
  });
}
