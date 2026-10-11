import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../modelos/alerta.dart';
import '../../modelos/capa_clima.dart';
import '../../modelos/enums.dart';
import '../../modelos/parcela.dart';
import '../../repositorios/preferencias_locales_repositorio.dart';
import '../../servicios/alertas_servicio.dart';
import '../../servicios/clima_servicio.dart';
import '../../servicios/conectividad_servicio.dart';
import '../../servicios/parcelas_servicio.dart';

/// Mapa del clima (pantalla 20, HU-09): sus parcelas con el color de su
/// aviso más alto y, si lo pide, una capa del clima de OpenWeather encima.
/// Ninguna capa se carga sola: cada tesela cuenta como consulta (RT-04).
class MapaClimaVm extends ChangeNotifier {
  MapaClimaVm({
    required this._parcelas,
    required this._alertas,
    required this._clima,
    required this._preferencias,
    required this._conectividad,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now {
    _suscripciones.addAll([
      _parcelas.misParcelas().listen((lista) {
        _lista = lista;
        _avisar();
      }, onError: (Object e) => debugPrint('Parcelas del mapa: $e')),
      _alertas.misAlertas().listen((lista) {
        _todas = lista;
        _avisar();
      }, onError: (Object e) => debugPrint('Alertas del mapa: $e')),
      _conectividad.cambios.listen((red) {
        _hayRed = red;
        _avisar();
      }, onError: (Object e) => debugPrint('Conexión del mapa: $e')),
    ]);
    unawaited(
      _conectividad.hayRed().then((red) {
        _hayRed = red;
        _avisar();
      }),
    );
  }

  final ParcelasServicio _parcelas;
  final AlertasServicio _alertas;
  final ClimaServicio _clima;
  final PreferenciasLocalesRepositorio _preferencias;
  final ConectividadServicio _conectividad;
  final DateTime Function() _reloj;
  final List<StreamSubscription<Object?>> _suscripciones = [];
  bool _descartado = false;

  List<Parcela> _lista = const [];
  List<Alerta> _todas = const [];
  bool _hayRed = true;
  CapaClima? _capa;
  double _opacidad = 0.7;
  bool _errorCapa = false;

  List<Parcela> get parcelas => _lista;
  bool get hayRed => _hayRed;
  CapaClima? get capa => _capa;
  double get opacidad => _opacidad;
  bool get errorCapa => _errorCapa;

  /// Plantilla de teselas de la capa elegida, o `null` si no hay capa.
  String? get urlCapa => _capa == null ? null : _clima.urlCapa(_capa!);

  /// Nivel del aviso activo más alto de cada parcela (para el color del pin).
  Map<String, NivelSeveridad> get nivelPorParcela {
    final niveles = <String, NivelSeveridad>{};
    for (final alerta in AlertasServicio.activas(_todas, _reloj())) {
      final otro = niveles[alerta.parcelaId];
      if (otro == null || alerta.nivel.index > otro.index) {
        niveles[alerta.parcelaId] = alerta.nivel;
      }
    }
    return niveles;
  }

  /// La parcela elegida en el panel o, si no, la primera.
  Parcela? get miParcela {
    if (_lista.isEmpty) return null;
    final elegida = _preferencias.parcelaSeleccionada;
    return _lista.firstWhere(
      (p) => p.parcelaId == elegida,
      orElse: () => _lista.first,
    );
  }

  /// Tocar la capa activa la quita.
  void elegirCapa(CapaClima capa) {
    _capa = _capa == capa ? null : capa;
    _errorCapa = false;
    _avisar();
  }

  void cambiarOpacidad(double valor) {
    _opacidad = valor.clamp(0.2, 1.0);
    _avisar();
  }

  /// Una tesela de la capa no llegó: se avisa una vez, el mapa sigue.
  void capaFallo() {
    if (_errorCapa || _capa == null) return;
    _errorCapa = true;
    _avisar();
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    for (final s in _suscripciones) {
      s.cancel();
    }
    super.dispose();
  }
}
