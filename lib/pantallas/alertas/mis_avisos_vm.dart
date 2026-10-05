import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../modelos/enums.dart';
import '../../modelos/parcela.dart';
import '../../modelos/preferencia_alerta.dart';
import '../../modelos/umbral.dart';
import '../../servicios/avisos_servicio.dart';
import '../../servicios/parcelas_servicio.dart';

/// "Mis avisos" (pantalla 23, HU-12). Cada cambio se guarda al tocar, sin
/// botón de guardar; se ve al instante aunque no haya señal.
class MisAvisosVm extends ChangeNotifier {
  MisAvisosVm({required this._avisos, required this._parcelas}) {
    _suscripcion = _avisos.misPreferencias().listen((lista) {
      _preferencias = lista;
      _cargando = false;
      _avisar();
    }, onError: (Object e) => debugPrint('Preferencias de avisos: $e'));
    _suscripcionParcelas = _parcelas.misParcelas().listen(
      _cargarLimites,
      onError: (Object e) => debugPrint('Parcelas de mis avisos: $e'),
    );
  }

  final AvisosServicio _avisos;
  final ParcelasServicio _parcelas;
  late final StreamSubscription<List<PreferenciaAlerta>> _suscripcion;
  late final StreamSubscription<List<Parcela>> _suscripcionParcelas;
  bool _descartado = false;

  List<PreferenciaAlerta> _preferencias = AvisosServicio.completar(const []);
  Map<Cultivo?, List<Umbral>> _limites = const {};
  bool _cargando = true;

  bool get cargando => _cargando;
  List<PreferenciaAlerta> get preferencias => _preferencias;

  /// Lo que aguanta cada cultivo de sus parcelas (informativo, D-20).
  Map<Cultivo?, List<Umbral>> get limites => _limites;

  /// "Avisarme desde": todas comparten el nivel; si no, el de la primera.
  NivelSeveridad get nivelMinimo => _preferencias.first.nivelMinimo;
  bool get silencioActivo => _preferencias.first.silencioActivo;
  String get silencioDesde => _preferencias.first.silencioActivo
      ? _preferencias.first.silencioDesde
      : PreferenciaAlerta.silencioDesdePorDefecto;
  String get silencioHasta => _preferencias.first.silencioActivo
      ? _preferencias.first.silencioHasta
      : PreferenciaAlerta.silencioHastaPorDefecto;

  void cambiarActiva(TipoRiesgo tipo, bool activa) =>
      _guardar(AvisosServicio.conActiva(_preferencias, tipo, activa));

  void cambiarNivelMinimo(NivelSeveridad nivel) =>
      _guardar(AvisosServicio.conNivelMinimo(_preferencias, nivel));

  void cambiarSilencio(bool activo) =>
      _guardar(AvisosServicio.conSilencio(_preferencias, activo));

  void _guardar(List<PreferenciaAlerta> nuevas) {
    _preferencias = nuevas;
    _avisar();
    unawaited(_avisos.guardar(nuevas));
  }

  Future<void> _cargarLimites(List<Parcela> parcelas) async {
    try {
      _limites = await _avisos.loQueAguanta(parcelas);
      _avisar();
    } catch (e) {
      debugPrint('Lo que aguanta el cultivo: $e');
    }
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _suscripcion.cancel();
    _suscripcionParcelas.cancel();
    super.dispose();
  }
}
