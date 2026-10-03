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
}
