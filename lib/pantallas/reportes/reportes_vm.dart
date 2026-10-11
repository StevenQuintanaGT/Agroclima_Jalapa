import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../modelos/alerta.dart';
import '../../modelos/parcela.dart';
import '../../modelos/registro_dia.dart';
import '../../repositorios/preferencias_locales_repositorio.dart';
import '../../servicios/alertas_servicio.dart';
import '../../servicios/compartir_servicio.dart';
import '../../servicios/exportar_reporte.dart';
import '../../servicios/parcelas_servicio.dart';
import '../../servicios/reportes_servicio.dart';

/// Períodos de la pantalla 25: 7 días, 30 días o elegidos en el calendario.
enum OpcionPeriodo { siete, treinta, elegido }

/// Resultado de una exportación, para avisar en pantalla.
enum ResultadoExportar { listo, sinImpresora }

/// Reportes (pantallas 25 y 27, HU-16): resumen de una parcela en un
/// período y "Guardar o enviar" en PDF, Excel o CSV, o imprimir (D-51).
class ReportesVm extends ChangeNotifier {
  ReportesVm({
    required this._parcelas,
    required this._alertas,
    required this._reportes,
    required this._compartir,
    required this._preferencias,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now {
    _periodo = Periodo.ultimosDias(7, _reloj());
    _suscripciones.addAll([
      _parcelas.misParcelas().listen((lista) {
        _lista = lista;
        final elegida =
            _parcela?.parcelaId ?? _preferencias.parcelaSeleccionada;
        final nueva = lista.isEmpty
            ? null
            : lista.firstWhere(
                (p) => p.parcelaId == elegida,
                orElse: () => lista.first,
              );
        final cambio = nueva?.parcelaId != _parcela?.parcelaId;
        _parcela = nueva;
        _cargandoParcelas = false;
        if (cambio) _escucharRegistros();
        _avisar();
      }, onError: (Object e) => debugPrint('Parcelas de reportes: $e')),
      _alertas.misAlertas().listen((lista) {
        _todas = lista;
        _avisar();
      }, onError: (Object e) => debugPrint('Avisos de reportes: $e')),
    ]);
  }

  final ParcelasServicio _parcelas;
  final AlertasServicio _alertas;
  final ReportesServicio _reportes;
  final CompartirServicio _compartir;
  final PreferenciasLocalesRepositorio _preferencias;
  final DateTime Function() _reloj;

  final List<StreamSubscription<Object?>> _suscripciones = [];
  StreamSubscription<List<RegistroDia>>? _suscripcionRegistros;
  bool _descartado = false;

  List<Parcela> _lista = const [];
  Parcela? _parcela;
  List<RegistroDia> _registros = const [];
  List<Alerta> _todas = const [];
  bool _cargandoParcelas = true;
  bool _cargandoRegistros = false;
  late Periodo _periodo;
  OpcionPeriodo _opcion = OpcionPeriodo.siete;
  FormatoReporte _formato = FormatoReporte.pdf;
  bool _exportando = false;

  List<Parcela> get parcelas => _lista;
  Parcela? get parcela => _parcela;
  bool get cargando => _cargandoParcelas || _cargandoRegistros;
  bool get sinParcelas => !_cargandoParcelas && _lista.isEmpty;
  Periodo get periodo => _periodo;
  OpcionPeriodo get opcion => _opcion;
  FormatoReporte get formato => _formato;
  bool get exportando => _exportando;
  DateTime get ahora => _reloj();

  ResumenPeriodo? get resumen => _parcela == null
      ? null
      : ReportesServicio.calcular(
          parcela: _parcela!,
          periodo: _periodo,
          registros: _registros,
          alertas: _todas,
        );

  void elegirParcela(Parcela parcela) {
    if (parcela.parcelaId == _parcela?.parcelaId) return;
    _parcela = parcela;
    unawaited(_preferencias.elegirParcela(parcela.parcelaId));
    _escucharRegistros();
    _avisar();
  }

  /// 7 o 30 días hasta hoy, o el período que eligió en el calendario.
  void elegirPeriodo(OpcionPeriodo opcion, {Periodo? elegido}) {
    final nuevo = switch (opcion) {
      OpcionPeriodo.siete => Periodo.ultimosDias(7, _reloj()),
      OpcionPeriodo.treinta => Periodo.ultimosDias(30, _reloj()),
      OpcionPeriodo.elegido => elegido ?? _periodo,
    };
    _opcion = opcion;
    if (nuevo != _periodo) {
      _periodo = nuevo;
      _escucharRegistros();
    }
    _avisar();
  }

  void elegirFormato(FormatoReporte formato) {
    _formato = formato;
    _avisar();
  }

  /// Arma el archivo del formato elegido y abre el menú de compartir.
  Future<void> compartir() async {
    final r = resumen;
    if (r == null || _exportando) return;
    await _exportar(() async {
      final bytes = await ExportarReporte.archivo(r, _formato, ahora: _reloj());
      await _compartir.compartirArchivo(
        bytes,
        nombre: '${ReportesServicio.nombreArchivo(r)}.${_formato.extension}',
        tipoMime: _formato.tipoMime,
      );
    });
  }

  /// Imprime el PDF con el servicio de impresión de Android.
  Future<ResultadoExportar> imprimir() async {
    final r = resumen;
    if (r == null || _exportando) return ResultadoExportar.listo;
    var resultado = ResultadoExportar.listo;
    await _exportar(() async {
      final pdf = await ExportarReporte.pdf(r, ahora: _reloj());
      final pudo = await _compartir.imprimirPdf(
        pdf,
        nombre: ReportesServicio.nombreArchivo(r),
      );
      if (!pudo) resultado = ResultadoExportar.sinImpresora;
    });
    return resultado;
  }

  Future<void> _exportar(Future<void> Function() trabajo) async {
    _exportando = true;
    _avisar();
    try {
      await trabajo();
    } catch (e) {
      debugPrint('No se pudo armar el reporte: $e');
    } finally {
      _exportando = false;
      _avisar();
    }
  }

  void _escucharRegistros() {
    _suscripcionRegistros?.cancel();
    final parcela = _parcela;
    if (parcela == null) {
      _registros = const [];
      return;
    }
    _cargandoRegistros = true;
    _suscripcionRegistros = _reportes
        .registros(parcela.parcelaId, _periodo)
        .listen(
          (lista) {
            _registros = lista;
            _cargandoRegistros = false;
            _avisar();
          },
          onError: (Object e) {
            debugPrint('Días del reporte: $e');
            _cargandoRegistros = false;
            _avisar();
          },
        );
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _suscripcionRegistros?.cancel();
    for (final s in _suscripciones) {
      s.cancel();
    }
    super.dispose();
  }
}
