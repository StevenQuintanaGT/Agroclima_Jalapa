import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../modelos/alerta.dart';
import '../../servicios/alertas_servicio.dart';

/// Centro de alertas (pantallas 21 y 35, HU-11). Las alertas llegan en vivo:
/// si el ciclo crea una nueva mientras la pantalla está abierta, aparece sola.
class CentroAlertasVm extends ChangeNotifier {
  CentroAlertasVm(this._alertas, {DateTime Function()? reloj})
    : _reloj = reloj ?? DateTime.now {
    _suscripcion = _alertas.misAlertas().listen(
      (lista) {
        _todas = lista;
        _cargando = false;
        _avisar();
      },
      onError: (Object e) {
        debugPrint('Alertas: $e');
        _cargando = false;
        _avisar();
      },
    );
  }

  final AlertasServicio _alertas;
  final DateTime Function() _reloj;
  late final StreamSubscription<List<Alerta>> _suscripcion;
  bool _descartado = false;

  List<Alerta> _todas = const [];
  bool _cargando = true;

  bool get cargando => _cargando;
  DateTime get ahora => _reloj();
  List<Alerta> get activas => AlertasServicio.activas(_todas, _reloj());
  List<Alerta> get anteriores => AlertasServicio.anteriores(_todas, _reloj());
  int get sinLeer => AlertasServicio.sinLeer(_todas, _reloj());

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _suscripcion.cancel();
    super.dispose();
  }
}
