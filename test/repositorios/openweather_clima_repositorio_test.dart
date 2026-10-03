import 'package:agroclima_jalapa/modelos/clima_actual.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/franja_pronostico.dart';
import 'package:agroclima_jalapa/modelos/parcela.dart';
import 'package:agroclima_jalapa/repositorios/cache_local.dart';
import 'package:agroclima_jalapa/repositorios/openweather_clima_repositorio.dart';
import 'package:agroclima_jalapa/servicios/openweather_cliente.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ClienteFalso extends Mock implements OpenWeatherCliente {}

class _CacheEnMemoria implements CacheLocal {
  final datos = <String, String>{};

  @override
  Future<String?> leer(String clave) async => datos[clave];

  @override
  Future<void> guardar(String clave, String valor) async =>
      datos[clave] = valor;
}

const _parcela = Parcela(
  parcelaId: 'p1',
  usuarioId: 'u1',
  nombre: 'El Guayabal',
  municipio: Municipio.jalapa,
  latitud: 14.6339,
  longitud: -89.9889,
  celdaClima: '14.65_-90.00',
);

ClimaActual _clima(DateTime fecha, {double temperatura = 24}) => ClimaActual(
  fechaHora: fecha,
  temperatura: temperatura,
  sensacionTermica: temperatura + 1,
  humedadRelativa: 70,
  lluviaUltimaHora: 0,
  velocidadViento: 12,
  direccionViento: 45,
  codigoClima: 800,
);

void main() {
  late _ClienteFalso cliente;
  late _CacheEnMemoria cache;
  late FakeFirebaseFirestore db;
  late DateTime ahora;

  OpenWeatherClimaRepositorio repo() => OpenWeatherClimaRepositorio(
    cliente: cliente,
    cache: cache,
    db: db,
    reloj: () => ahora,
  );

  setUp(() {
    cliente = _ClienteFalso();
    cache = _CacheEnMemoria();
    db = FakeFirebaseFirestore();
    ahora = DateTime.utc(2026, 10, 3, 18);
  });

  group('caché primero (RNF-08)', () {
    test('sin caché va a la red, guarda y devuelve vigente', () async {
      when(() => cliente.actual(any(), any()))
          .thenAnswer((_) async => _clima(ahora));
      final resultado = await repo().actual(_parcela);
      expect(resultado.vigente, isTrue);
      expect(resultado.dato!.temperatura, 24);
      expect(resultado.fecha, ahora);
      expect(cache.datos.keys, ['clima.actual.14.65_-90.00']);
    });

    test('con dato vigente no llama a la red (RNF-11)', () async {
      when(() => cliente.actual(any(), any()))
          .thenAnswer((_) async => _clima(ahora));
      await repo().actual(_parcela);
      ahora = ahora.add(const Duration(minutes: 59));
      final resultado = await repo().actual(_parcela);
      expect(resultado.vigente, isTrue);
      verify(() => cliente.actual(any(), any())).called(1);
    });

    test('pasada la vigencia (60 min, D-08) vuelve a pedir', () async {
      when(() => cliente.actual(any(), any()))
          .thenAnswer((_) async => _clima(ahora));
      await repo().actual(_parcela);
      ahora = ahora.add(const Duration(minutes: 61));
      await repo().actual(_parcela);
      verify(() => cliente.actual(any(), any())).called(2);
    });

    test('si la red falla, devuelve lo guardado como no vigente', () async {
      when(() => cliente.actual(any(), any()))
          .thenAnswer((_) async => _clima(ahora));
      await repo().actual(_parcela);
      when(() => cliente.actual(any(), any()))
          .thenThrow(const ErrorClima(MotivoErrorClima.sinConexion));
      final guardado = ahora;
      ahora = ahora.add(const Duration(hours: 5));
      final resultado = await repo().actual(_parcela);
      expect(resultado.vigente, isFalse);
      expect(resultado.dato!.temperatura, 24);
      expect(resultado.fecha, guardado);
      expect(resultado.error, MotivoErrorClima.sinConexion);
    });

    test('"actualizar" con dato vigente que falla lo deja vigente', () async {
      when(() => cliente.actual(any(), any()))
          .thenAnswer((_) async => _clima(ahora));
      await repo().actual(_parcela);
      when(() => cliente.actual(any(), any()))
          .thenThrow(const ErrorClima(MotivoErrorClima.tiempoAgotado));
      final resultado = await repo().actual(_parcela, forzar: true);
      expect(resultado.vigente, isTrue);
      expect(resultado.error, MotivoErrorClima.tiempoAgotado);
    });

    test('sin caché y sin red: vacío con el motivo', () async {
      when(() => cliente.actual(any(), any()))
          .thenThrow(const ErrorClima(MotivoErrorClima.servicioCaido));
      final resultado = await repo().actual(_parcela);
      expect(resultado.hayDato, isFalse);
      expect(resultado.error, MotivoErrorClima.servicioCaido);
    });

    test('una caché dañada se ignora', () async {
      cache.datos['clima.actual.14.65_-90.00'] = '{roto';
      when(() => cliente.actual(any(), any()))
          .thenAnswer((_) async => _clima(ahora));
      expect((await repo().actual(_parcela)).vigente, isTrue);
    });

    test('parcelas de la misma celda comparten la consulta (RN-06)', () async {
      when(() => cliente.actual(any(), any()))
          .thenAnswer((_) async => _clima(ahora));
      await repo().actual(_parcela);
      const vecina = Parcela(
        parcelaId: 'p2',
        usuarioId: 'u1',
        nombre: 'Vecina',
        municipio: Municipio.jalapa,
        latitud: 14.64,
        longitud: -89.99,
        celdaClima: '14.65_-90.00',
      );
      await repo().actual(vecina);
      verify(() => cliente.actual(any(), any())).called(1);
    });
  });

  test('el pronóstico por horas vale 3 horas y se lee igual', () async {
    final franja = FranjaPronostico(
      fechaHora: ahora,
      temperatura: 20,
      temperaturaMinima: 18,
      temperaturaMaxima: 22,
      humedadRelativa: 80,
      lluvia3h: 1.5,
      velocidadViento: 10,
      probabilidadLluvia: 0.6,
      codigoClima: 500,
    );
    when(() => cliente.pronostico(any(), any()))
        .thenAnswer((_) async => [franja]);
    await repo().porHoras(_parcela);
    ahora = ahora.add(const Duration(hours: 2, minutes: 59));
    final resultado = await repo().porHoras(_parcela);
    expect(resultado.dato!.single.probabilidadLluvia, 0.6);
    verify(() => cliente.pronostico(any(), any())).called(1);
  });

  test('guarda la consulta en condiciones/{hoy} con origen consulta', () async {
    when(() => cliente.actual(any(), any()))
        .thenAnswer((_) async => _clima(DateTime.utc(2026, 10, 3, 17, 50)));
    await repo().actual(_parcela);
    await pumpEventQueue();
    final doc = await db.doc('parcelas/p1/condiciones/20261003').get();
    expect(doc.data(), {
      'fecha': '20261003',
      'temperatura': 24.0,
      'humedadRelativa': 70.0,
      'velocidadViento': 12.0,
      'origen': 'consulta',
      'vigente': true,
      'fechaHora': Timestamp.fromDate(DateTime.utc(2026, 10, 3, 17, 50)),
    });
  });

  test('lee la lluvia del día que dejó el ciclo', () async {
    await db.doc('parcelas/p1/condiciones/20261003').set({
      'fecha': '20261003',
      'fechaHora': Timestamp.fromDate(ahora),
      'temperatura': 22.0,
      'humedadRelativa': 80.0,
      'velocidadViento': 5.0,
      'precipitacion': 4.5,
      'origen': 'ciclo',
    });
    final condicion = await repo().condicionDeHoy('p1').first;
    expect(condicion!.precipitacion, 4.5);
  });

  test('los próximos días empiezan hoy, en orden', () async {
    for (final fecha in ['20261002', '20261004', '20261003']) {
      await db.doc('parcelas/p1/pronosticos/$fecha').set({
        'fecha': fecha,
        'temperaturaMinima': 14.0,
        'temperaturaMaxima': 26.0,
        'precipitacionHora': 0.0,
        'acumuladoDia': 0.0,
        'velocidadViento': 10.0,
        'humedadRelativa': 80.0,
      });
    }
    final dias = await repo().proximosDias('p1').first;
    expect(dias.map((d) => d.fecha), ['20261003', '20261004']);
  });
}
