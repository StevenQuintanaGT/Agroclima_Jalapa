import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agroclima_jalapa/servicios/openweather_cliente.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../apoyo/openweather_muestras.dart';

OpenWeatherCliente _cliente(
  Future<http.Response> Function(http.Request) responder, {
  Duration espera = const Duration(seconds: 5),
}) => OpenWeatherCliente(
  clave: 'clave-de-prueba',
  cliente: MockClient(responder),
  espera: espera,
);

http.Response _json(Object cuerpo, [int estado = 200]) =>
    http.Response(jsonEncode(cuerpo), estado);

Matcher _falla(MotivoErrorClima motivo) =>
    throwsA(isA<ErrorClima>().having((e) => e.motivo, 'motivo', motivo));

void main() {
  group('clima actual', () {
    test('pide Current Weather 2.5 en métrico y español', () async {
      late Uri pedida;
      final cliente = _cliente((peticion) async {
        pedida = peticion.url;
        return _json(actualMuestra());
      });
      await cliente.actual(14.63391, -89.98889);
      expect(pedida.host, 'api.openweathermap.org');
      expect(pedida.path, '/data/2.5/weather');
      expect(pedida.queryParameters, {
        'lat': '14.6339',
        'lon': '-89.9889',
        'units': 'metric',
        'lang': 'es',
        'appid': 'clave-de-prueba',
      });
    });

    test('traduce al dominio con viento en km/h', () async {
      final cliente = _cliente(
        (_) async => _json(actualMuestra(lluvia1h: 1.2)),
      );
      final clima = await cliente.actual(14.63, -89.99);
      expect(clima.temperatura, 24.5);
      expect(clima.sensacionTermica, 25.1);
      expect(clima.humedadRelativa, 70);
      expect(clima.velocidadViento, 18); // 5 m/s × 3.6
      expect(clima.lluviaUltimaHora, 1.2);
      expect(clima.codigoClima, 500);
      expect(clima.fechaHora, DateTime.utc(2026, 10, 3, 18));
      expect(clima.salidaSol, isNotNull);
    });

    test('sin lluvia en la respuesta, la lluvia es 0', () async {
      final cliente = _cliente((_) async => _json(actualMuestra()));
      expect((await cliente.actual(14.63, -89.99)).lluviaUltimaHora, 0);
    });

    test('respuesta incompleta se descarta (VA-06)', () async {
      final cliente = _cliente(
        (_) async => _json(actualMuestra(humedad: null)),
      );
      expect(
        cliente.actual(14.63, -89.99),
        _falla(MotivoErrorClima.respuestaInvalida),
      );
    });

    test('valores imposibles para Jalapa se descartan (VA-07)', () async {
      final cliente = _cliente(
        (_) async => _json(actualMuestra(temperatura: 60)),
      );
      expect(
        cliente.actual(14.63, -89.99),
        _falla(MotivoErrorClima.respuestaInvalida),
      );
    });

    test('texto que no es JSON se descarta', () async {
      final cliente = _cliente((_) async => http.Response('<html>', 200));
      expect(
        cliente.actual(14.63, -89.99),
        _falla(MotivoErrorClima.respuestaInvalida),
      );
    });
  });

  group('errores del servicio', () {
    test('clave rechazada', () {
      final cliente = _cliente((_) async => _json({'cod': 401}, 401));
      expect(
        cliente.actual(14.63, -89.99),
        _falla(MotivoErrorClima.claveInvalida),
      );
    });

    test('límite de consultas alcanzado', () {
      final cliente = _cliente((_) async => _json({'cod': 429}, 429));
      expect(
        cliente.pronostico(14.63, -89.99),
        _falla(MotivoErrorClima.limiteAlcanzado),
      );
    });

    test('servicio caído', () {
      final cliente = _cliente((_) async => http.Response('', 503));
      expect(
        cliente.actual(14.63, -89.99),
        _falla(MotivoErrorClima.servicioCaido),
      );
    });

    test('sin señal', () {
      final cliente = _cliente(
        (_) async => throw const SocketException('sin red'),
      );
      expect(
        cliente.actual(14.63, -89.99),
        _falla(MotivoErrorClima.sinConexion),
      );
    });

    test('más de 5 s sin respuesta (RNF-07)', () {
      final cliente = _cliente(
        (_) => Completer<http.Response>().future,
        espera: const Duration(milliseconds: 10),
      );
      expect(
        cliente.actual(14.63, -89.99),
        _falla(MotivoErrorClima.tiempoAgotado),
      );
    });
  });

  group('pronóstico', () {
    test('pide Forecast 2.5 y devuelve las 40 franjas en orden', () async {
      late Uri pedida;
      final cliente = _cliente((peticion) async {
        pedida = peticion.url;
        final cuerpo = pronosticoMuestra();
        (cuerpo['list'] as List).shuffle();
        return _json(cuerpo);
      });
      final franjas = await cliente.pronostico(14.63, -89.99);
      expect(pedida.path, '/data/2.5/forecast');
      expect(franjas, hasLength(40));
      expect(franjas.first.fechaHora, DateTime.utc(2026, 10, 3, 6));
      expect(franjas.last.fechaHora, DateTime.utc(2026, 10, 8, 3));
    });

    test('traduce lluvia, viento y probabilidad', () async {
      final cliente = _cliente(
        (_) async => _json({
          'list': [franjaMuestra(mediodia3Oct, lluvia3h: 9, viento: 10)],
        }),
      );
      final franja = (await cliente.pronostico(14.63, -89.99)).single;
      expect(franja.lluvia3h, 9);
      expect(franja.lluviaPorHora, 3);
      expect(franja.velocidadViento, 36);
      expect(franja.probabilidadLluvia, 0.4);
    });

    test('una franja imposible descarta toda la respuesta (VA-07)', () {
      final cuerpo = pronosticoMuestra();
      (cuerpo['list'] as List)[5] = franjaMuestra(mediodia3Oct, humedad: 140);
      final cliente = _cliente((_) async => _json(cuerpo));
      expect(
        cliente.pronostico(14.63, -89.99),
        _falla(MotivoErrorClima.respuestaInvalida),
      );
    });

    test('lista vacía se descarta (VA-06)', () {
      final cliente = _cliente((_) async => _json({'list': []}));
      expect(
        cliente.pronostico(14.63, -89.99),
        _falla(MotivoErrorClima.respuestaInvalida),
      );
    });
  });
}
