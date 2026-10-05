import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/constantes.dart';
import '../modelos/capa_clima.dart';
import '../modelos/clima_actual.dart';
import '../modelos/condicion.dart';
import '../modelos/franja_pronostico.dart';
import '../modelos/parcela.dart';
import '../modelos/pronostico_dia.dart';
import '../modelos/resultado.dart';
import '../servicios/openweather_cliente.dart';
import '../utilidades/fechas.dart';
import 'cache_local.dart';
import 'clima_repositorio.dart';

/// [ClimaRepositorio] con OpenWeather (fachada), una caché en el teléfono por
/// celda climática y Firestore.
///
/// - La caché del teléfono guarda el último clima actual y el pronóstico por
///   horas de cada celda, con la hora en que se consultaron: parcelas de la
///   misma celda comparten la consulta (RN-06) y no se vuelve a pedir lo que
///   sigue vigente (RNF-11).
/// - Cada consulta exitosa del clima actual queda en `condiciones/{hoy}` con
///   `origen: consulta` para el historial (HU-13). Firestore la sube sola
///   cuando haya señal.
class OpenWeatherClimaRepositorio implements ClimaRepositorio {
  OpenWeatherClimaRepositorio({
    required this._cliente,
    required this._cache,
    this._db,
    DateTime Function()? reloj,
    this.vigenciaActual = Constantes.vigenciaCondiciones,
    this.vigenciaPronostico = Constantes.vigenciaPronostico,
  }) : _reloj = reloj ?? DateTime.now;

  final OpenWeatherCliente _cliente;
  final CacheLocal _cache;
  final FirebaseFirestore? _db;
  final DateTime Function() _reloj;
  final Duration vigenciaActual;
  final Duration vigenciaPronostico;

  FirebaseFirestore get _firestore => _db ?? FirebaseFirestore.instance;

  @override
  Future<Resultado<ClimaActual>> actual(
    Parcela parcela, {
    bool forzar = false,
  }) => _cachePrimero(
    clave: 'clima.actual.${parcela.celdaClima}',
    vigencia: vigenciaActual,
    forzar: forzar,
    leer: (json) => ClimaActual.fromMap(json as Map<String, dynamic>),
    escribir: (clima) => clima.toMap(),
    pedir: () => _cliente.actual(parcela.latitud, parcela.longitud),
    alObtener: (clima) => _guardarCondicion(parcela, clima),
  );

  @override
  Future<Resultado<List<FranjaPronostico>>> porHoras(
    Parcela parcela, {
    bool forzar = false,
  }) => _cachePrimero(
    clave: 'clima.horas.${parcela.celdaClima}',
    vigencia: vigenciaPronostico,
    forzar: forzar,
    leer: (json) => [
      for (final franja in json as List<dynamic>)
        FranjaPronostico.fromMap(franja as Map<String, dynamic>),
    ],
    escribir: (franjas) => [for (final franja in franjas) franja.toMap()],
    pedir: () => _cliente.pronostico(parcela.latitud, parcela.longitud),
  );

  @override
  Stream<Condicion?> condicionDeHoy(String parcelaId) => _firestore
      .doc(
        'parcelas/$parcelaId/condiciones/${Fechas.idDiario(_reloj().toUtc())}',
      )
      .snapshots()
      .map((doc) {
        final datos = doc.data();
        final fecha = datos?['fechaHora'];
        if (datos == null ||
            fecha is! Timestamp ||
            datos['temperatura'] == null) {
          return null;
        }
        return Condicion.fromMap(datos, fechaHora: fecha.toDate());
      });

  @override
  String urlCapa(CapaClima capa) => _cliente.urlTeselas(capa);

  @override
  Stream<List<PronosticoDia>> proximosDias(String parcelaId) => _firestore
      .collection('parcelas/$parcelaId/pronosticos')
      .where(
        FieldPath.documentId,
        isGreaterThanOrEqualTo: Fechas.idDiario(_reloj().toUtc()),
      )
      .orderBy(FieldPath.documentId)
      .limit(Constantes.diasPronostico)
      .snapshots()
      .map(
        (consulta) => [
          for (final doc in consulta.docs)
            PronosticoDia.fromMap(
              doc.data(),
              fechaConsulta: (doc.data()['fechaConsulta'] as Timestamp?)
                  ?.toDate(),
            ),
        ],
      );

  /// Caché primero (plans/03 §4).
  Future<Resultado<T>> _cachePrimero<T>({
    required String clave,
    required Duration vigencia,
    required bool forzar,
    required T Function(Object json) leer,
    required Object Function(T dato) escribir,
    required Future<T> Function() pedir,
    void Function(T dato)? alObtener,
  }) async {
    final guardado = await _leerCache(clave, leer);
    final ahora = _reloj().toUtc();
    final vigente =
        guardado != null && ahora.difference(guardado.fecha) < vigencia;
    if (vigente && !forzar) {
      return Resultado(
        dato: guardado.dato,
        fecha: guardado.fecha,
        vigente: true,
      );
    }
    try {
      final dato = await pedir();
      await _cache.guardar(
        clave,
        jsonEncode({
          'consultado': ahora.millisecondsSinceEpoch,
          'dato': escribir(dato),
        }),
      );
      alObtener?.call(dato);
      return Resultado(dato: dato, fecha: ahora, vigente: true);
    } on ErrorClima catch (error) {
      if (guardado == null) return Resultado.vacio(error.motivo);
      // Lo guardado sigue siendo vigente si solo se quiso actualizar antes.
      return Resultado(
        dato: guardado.dato,
        fecha: guardado.fecha,
        vigente: vigente,
        error: error.motivo,
      );
    }
  }

  Future<({T dato, DateTime fecha})?> _leerCache<T>(
    String clave,
    T Function(Object json) leer,
  ) async {
    try {
      final texto = await _cache.leer(clave);
      if (texto == null) return null;
      final json = jsonDecode(texto) as Map<String, dynamic>;
      return (
        dato: leer(json['dato'] as Object),
        fecha: DateTime.fromMillisecondsSinceEpoch(
          json['consultado'] as int,
          isUtc: true,
        ),
      );
    } catch (error) {
      // Caché dañada o de una versión vieja: se ignora y se vuelve a pedir.
      debugPrint('Caché de clima ilegible ($clave): $error');
      return null;
    }
  }

  /// Sin esperar: si no hay señal, Firestore la sube después.
  void _guardarCondicion(Parcela parcela, ClimaActual clima) {
    final condicion = Condicion(
      fecha: Fechas.idDiario(clima.fechaHora),
      fechaHora: clima.fechaHora,
      temperatura: clima.temperatura,
      humedadRelativa: clima.humedadRelativa,
      velocidadViento: clima.velocidadViento,
    );
    _firestore
        .doc('parcelas/${parcela.parcelaId}/condiciones/${condicion.fecha}')
        .set({
          ...condicion.toMapConsulta(),
          'fechaHora': Timestamp.fromDate(clima.fechaHora),
        }, SetOptions(merge: true))
        .catchError((Object error) {
          debugPrint('No se guardó la condición consultada: $error');
        });
  }
}
