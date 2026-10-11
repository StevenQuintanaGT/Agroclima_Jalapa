import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../modelos/alerta.dart';
import '../../modelos/parcela.dart';
import '../../modelos/registro_dia.dart';
import '../../servicios/alertas_servicio.dart';
import '../../servicios/historial_servicio.dart';
import '../../servicios/parcelas_servicio.dart';
import '../../utilidades/fechas.dart';

/// Historial día por día de una parcela (pantalla 26, HU-13). Solo muestra
/// lo guardado: funciona sin señal con la copia del teléfono.
class HistorialVm extends ChangeNotifier {
  HistorialVm({
    required this._historial,
    required this._alertas,
    required this._parcelas,
    required this.parcelaId,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now {
    _suscripciones.addAll([
      _parcelas.observar(parcelaId).listen((p) {
        _parcela = p;
        _avisar();
      }, onError: (Object e) => debugPrint('Parcela del historial: $e')),
      _alertas.misAlertas().listen((lista) {
        _alertasParcela = [
          for (final a in lista)
            if (a.parcelaId == parcelaId) a,
        ];
        _avisar();
      }, onError: (Object e) => debugPrint('Avisos del historial: $e')),
    ]);
    _escucharDias();
  }

  final HistorialServicio _historial;
  final AlertasServicio _alertas;
  final ParcelasServicio _parcelas;
  final String parcelaId;
  final DateTime Function() _reloj;

  final List<StreamSubscription<Object?>> _suscripciones = [];
  StreamSubscription<List<RegistroDia>>? _suscripcionDias;
  bool _descartado = false;

  Parcela? _parcela;
  List<RegistroDia> _registros = const [];
  List<Alerta> _alertasParcela = const [];
  bool _cargando = true;
  bool _cargandoMas = false;
  int _limite = HistorialServicio.diasPorPagina;
  FiltroHistorial _filtro = FiltroHistorial.todo;

  Parcela? get parcela => _parcela;

  /// Id `yyyyMMdd` de hoy en Guatemala (esa fila dice "Hoy").
  String get hoy => Fechas.idDiario(_reloj());
  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  FiltroHistorial get filtro => _filtro;

  /// ¿Hay algún día guardado (sin filtro)?
  bool get hayDias => _registros.isNotEmpty;

  /// Si llegaron tantos días como se pidieron, puede haber más viejos.
  bool get hayMas => _registros.length >= _limite;

  List<DiaHistorial> get dias => HistorialServicio.filtrar(
    HistorialServicio.conAvisos(_registros, _alertasParcela),
    _filtro,
  );

  void elegirFiltro(FiltroHistorial filtro) {
    _filtro = filtro;
    _avisar();
  }

  /// "Ver días anteriores": otros 30 hacia atrás.
  void verMas() {
    if (_cargandoMas || !hayMas) return;
    _limite += HistorialServicio.diasPorPagina;
    _cargandoMas = true;
    _avisar();
    _escucharDias();
  }

  void _escucharDias() {
    _suscripcionDias?.cancel();
    _suscripcionDias = _historial
        .dias(parcelaId, limite: _limite)
        .listen(
          (registros) {
            _registros = registros;
            _cargando = false;
            _cargandoMas = false;
            _avisar();
          },
          onError: (Object e) {
            debugPrint('Historial: $e');
            _cargando = false;
            _cargandoMas = false;
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
    _suscripcionDias?.cancel();
    for (final s in _suscripciones) {
      s.cancel();
    }
    super.dispose();
  }
}
