import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../config/constantes.dart';
import '../../modelos/alerta.dart';
import '../../servicios/alertas_servicio.dart';

/// Centro de alertas (pantallas 21 y 35, HU-11) e historial de alertas
/// (pestaña Anteriores, HU-14). Las alertas llegan en vivo: si el ciclo crea
/// una nueva mientras la pantalla está abierta, aparece sola.
class CentroAlertasVm extends ChangeNotifier {
  CentroAlertasVm(this._alertas, {DateTime Function()? reloj})
    : _reloj = reloj ?? DateTime.now {
    _escuchar();
  }

  final AlertasServicio _alertas;
  final DateTime Function() _reloj;
  StreamSubscription<List<Alerta>>? _suscripcion;
  bool _descartado = false;

  List<Alerta> _todas = const [];
  bool _cargando = true;
  int _limite = Constantes.alertasEnLista;
  bool _cargandoMas = false;
  String? _parcelaFiltro;

  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  DateTime get ahora => _reloj();
  List<Alerta> get activas => AlertasServicio.activas(_todas, _reloj());
  int get sinLeer => AlertasServicio.sinLeer(_todas, _reloj());

  /// Historial (HU-14): días pasados, de una parcela o de todas.
  List<Alerta> get anteriores {
    final lista = AlertasServicio.anteriores(_todas, _reloj());
    final filtro = _parcelaFiltro;
    return filtro == null
        ? lista
        : lista.where((a) => a.parcelaId == filtro).toList();
  }

  /// Parcelas con avisos anteriores, para el filtro: (parcelaId, nombre).
  List<(String, String)> get parcelasAnteriores =>
      AlertasServicio.parcelasDe(AlertasServicio.anteriores(_todas, _reloj()));

  /// `null` = todas las parcelas.
  String? get parcelaFiltro => _parcelaFiltro;

  /// Si llegaron tantas como se pidieron, puede haber más viejas.
  bool get hayMas => _todas.length >= _limite;

  void filtrarParcela(String? parcelaId) {
    _parcelaFiltro = parcelaId;
    _avisar();
  }

  /// "Ver más avisos": pide otras tantas hacia atrás.
  void verMas() {
    if (_cargandoMas || !hayMas) return;
    _limite += Constantes.alertasEnLista;
    _cargandoMas = true;
    _avisar();
    _escuchar();
  }

  void _escuchar() {
    _suscripcion?.cancel();
    final flujo = _limite == Constantes.alertasEnLista
        ? _alertas.misAlertas()
        : _alertas.misAlertas(limite: _limite);
    _suscripcion = flujo.listen(
      (lista) {
        _todas = lista;
        _cargando = false;
        _cargandoMas = false;
        _avisar();
      },
      onError: (Object e) {
        debugPrint('Alertas: $e');
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
    _suscripcion?.cancel();
    super.dispose();
  }
}
