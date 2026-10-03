import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/constantes.dart';
import '../modelos/clima_actual.dart';
import '../modelos/franja_pronostico.dart';
import '../utilidades/unidades.dart';
import 'validacion_clima.dart';

/// Por qué no se pudo traer el clima. La pantalla lo convierte en una causa
/// probable en lenguaje llano (pantalla 34); nunca se muestra el código.
enum MotivoErrorClima {
  sinConexion,
  tiempoAgotado,
  claveInvalida,
  limiteAlcanzado,
  servicioCaido,
  respuestaInvalida,
}

class ErrorClima implements Exception {
  const ErrorClima(this.motivo);

  final MotivoErrorClima motivo;

  @override
  String toString() => 'ErrorClima($motivo)';
}

/// FACHADA del proveedor del clima (OpenWeather, plan gratuito; D-09). Arma
/// las peticiones, traduce la respuesta al dominio y valida (VA-06, VA-07):
/// ninguna otra capa ve el JSON del proveedor. Solo la usa el repositorio de
/// clima, así que cambiar de proveedor no toca la presentación (RNF-20).
class OpenWeatherCliente {
  OpenWeatherCliente({
    required this._clave,
    http.Client? cliente,
    this.espera = Constantes.esperaClima,
  }) : _http = cliente ?? http.Client();

  final String _clave;
  final http.Client _http;

  /// Tiempo máximo por consulta (RNF-07). En el teléfono no se reintenta:
  /// se muestra el dato guardado y el productor decide "Intentar de nuevo".
  final Duration espera;

  static const String _base = 'api.openweathermap.org';

  /// Current Weather 2.5: clima de este momento en el punto.
  Future<ClimaActual> actual(double latitud, double longitud) async {
    final json = await _pedir('/data/2.5/weather', latitud, longitud);
    try {
      final clima = traducirActual(json);
      if (clima != null) return clima;
    } catch (error) {
      debugPrint('Clima actual con formato inesperado: $error');
    }
    throw const ErrorClima(MotivoErrorClima.respuestaInvalida);
  }

  /// 5 day / 3 hour Forecast 2.5: hasta 40 franjas de 3 h.
  Future<List<FranjaPronostico>> pronostico(
    double latitud,
    double longitud,
  ) async {
    final json = await _pedir('/data/2.5/forecast', latitud, longitud);
    try {
      final franjas = traducirPronostico(json);
      if (franjas != null) return franjas;
    } catch (error) {
      debugPrint('Pronóstico con formato inesperado: $error');
    }
    throw const ErrorClima(MotivoErrorClima.respuestaInvalida);
  }

  Future<Map<String, dynamic>> _pedir(
    String ruta,
    double latitud,
    double longitud,
  ) async {
    final uri = Uri.https(_base, ruta, {
      'lat': latitud.toStringAsFixed(4),
      'lon': longitud.toStringAsFixed(4),
      'units': 'metric',
      'lang': 'es',
      'appid': _clave,
    });
    final http.Response respuesta;
    try {
      respuesta = await _http.get(uri).timeout(espera);
    } on TimeoutException {
      throw const ErrorClima(MotivoErrorClima.tiempoAgotado);
    } catch (error) {
      // SocketException, ClientException…: sin señal o sin ruta al servidor.
      debugPrint('Sin conexión con el proveedor del clima: $error');
      throw const ErrorClima(MotivoErrorClima.sinConexion);
    }
    switch (respuesta.statusCode) {
      case 200:
        break;
      case 401:
        throw const ErrorClima(MotivoErrorClima.claveInvalida);
      case 429:
        throw const ErrorClima(MotivoErrorClima.limiteAlcanzado);
      default:
        throw const ErrorClima(MotivoErrorClima.servicioCaido);
    }
    try {
      return jsonDecode(respuesta.body) as Map<String, dynamic>;
    } catch (_) {
      throw const ErrorClima(MotivoErrorClima.respuestaInvalida);
    }
  }

  /// Traduce `/weather`. `null` si falta algo (VA-06) o está fuera de rango
  /// (VA-07).
  @visibleForTesting
  static ClimaActual? traducirActual(Map<String, dynamic> json) {
    final principal = json['main'] as Map<String, dynamic>?;
    final viento = json['wind'] as Map<String, dynamic>?;
    final dt = json['dt'] as num?;
    final temperatura = (principal?['temp'] as num?)?.toDouble();
    final humedad = (principal?['humidity'] as num?)?.toDouble();
    final velocidad = (viento?['speed'] as num?)?.toDouble();
    if (dt == null ||
        temperatura == null ||
        humedad == null ||
        velocidad == null) {
      return null;
    }
    final lluvia = _lluvia(json, '1h');
    final kmPorHora = Unidades.metrosPorSegundoAKmPorHora(velocidad);
    if (!ValidacionClima.enRango(
      temperatura: temperatura,
      humedadRelativa: humedad,
      velocidadViento: kmPorHora,
      lluviaPorHora: lluvia,
    )) {
      return null;
    }
    final sistema = json['sys'] as Map<String, dynamic>?;
    final condicion = _condicion(json);
    return ClimaActual(
      fechaHora: _instante(dt),
      temperatura: temperatura,
      sensacionTermica:
          (principal!['feels_like'] as num?)?.toDouble() ?? temperatura,
      humedadRelativa: humedad,
      lluviaUltimaHora: lluvia,
      velocidadViento: kmPorHora,
      codigoClima: condicion.codigo,
      descripcion: condicion.descripcion,
      salidaSol: _instanteOpcional(sistema?['sunrise']),
      puestaSol: _instanteOpcional(sistema?['sunset']),
    );
  }

  /// Traduce `/forecast`. `null` si alguna franja está incompleta o fuera de
  /// rango: se descarta toda la respuesta y queda el pronóstico previo.
  @visibleForTesting
  static List<FranjaPronostico>? traducirPronostico(Map<String, dynamic> json) {
    final lista = json['list'] as List<dynamic>?;
    if (lista == null || lista.isEmpty) return null;
    final franjas = <FranjaPronostico>[];
    for (final elemento in lista) {
      final franja = _franja(elemento as Map<String, dynamic>);
      if (franja == null) return null;
      franjas.add(franja);
    }
    return franjas..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
  }

  static FranjaPronostico? _franja(Map<String, dynamic> json) {
    final principal = json['main'] as Map<String, dynamic>?;
    final viento = json['wind'] as Map<String, dynamic>?;
    final dt = json['dt'] as num?;
    final temperatura = (principal?['temp'] as num?)?.toDouble();
    final humedad = (principal?['humidity'] as num?)?.toDouble();
    final velocidad = (viento?['speed'] as num?)?.toDouble();
    if (dt == null ||
        temperatura == null ||
        humedad == null ||
        velocidad == null) {
      return null;
    }
    final minima = (principal!['temp_min'] as num?)?.toDouble() ?? temperatura;
    final maxima = (principal['temp_max'] as num?)?.toDouble() ?? temperatura;
    final lluvia = _lluvia(json, '3h');
    final kmPorHora = Unidades.metrosPorSegundoAKmPorHora(velocidad);
    final valido =
        ValidacionClima.enRango(
          temperatura: minima,
          humedadRelativa: humedad,
          velocidadViento: kmPorHora,
          lluviaPorHora: lluvia / 3,
        ) &&
        ValidacionClima.enRango(
          temperatura: maxima,
          humedadRelativa: humedad,
          velocidadViento: kmPorHora,
        );
    if (!valido) return null;
    final condicion = _condicion(json);
    return FranjaPronostico(
      fechaHora: _instante(dt),
      temperatura: temperatura,
      temperaturaMinima: minima,
      temperaturaMaxima: maxima,
      humedadRelativa: humedad,
      lluvia3h: lluvia,
      velocidadViento: kmPorHora,
      probabilidadLluvia: (json['pop'] as num?)?.toDouble() ?? 0,
      codigoClima: condicion.codigo,
      descripcion: condicion.descripcion,
    );
  }

  static double _lluvia(Map<String, dynamic> json, String clave) =>
      ((json['rain'] as Map<String, dynamic>?)?[clave] as num?)?.toDouble() ??
      0;

  static ({int codigo, String descripcion}) _condicion(
    Map<String, dynamic> json,
  ) {
    final lista = json['weather'] as List<dynamic>?;
    final primera = lista == null || lista.isEmpty
        ? null
        : lista.first as Map<String, dynamic>;
    return (
      codigo: (primera?['id'] as num?)?.toInt() ?? 800,
      descripcion: primera?['description'] as String? ?? '',
    );
  }

  static DateTime _instante(num segundos) =>
      DateTime.fromMillisecondsSinceEpoch(segundos.toInt() * 1000, isUtc: true);

  static DateTime? _instanteOpcional(Object? segundos) =>
      segundos is num ? _instante(segundos) : null;
}
