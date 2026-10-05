import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../config/textos.dart';
import '../../modelos/alerta.dart';
import '../../modelos/parcela.dart';
import '../../servicios/alertas_servicio.dart';
import '../../servicios/compartir_servicio.dart';
import '../../servicios/parcelas_servicio.dart';

/// Detalle de alerta (pantalla 22, HU-11). Al abrirla queda como leída; se
/// ve aunque la notificación no haya llegado o no haya señal (RT-05).
class DetalleAlertaVm extends ChangeNotifier {
  DetalleAlertaVm({
    required this._alertas,
    required this._parcelas,
    required this._compartir,
    required this.alertaId,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now {
    _suscripcion = _alertas
        .observar(alertaId)
        .listen(
          _alRecibir,
          onError: (Object e) {
            debugPrint('Alerta $alertaId: $e');
            _cargando = false;
            _avisar();
          },
        );
  }

  final AlertasServicio _alertas;
  final ParcelasServicio _parcelas;
  final CompartirServicio _compartir;
  final String alertaId;
  final DateTime Function() _reloj;

  late final StreamSubscription<Alerta?> _suscripcion;
  StreamSubscription<Parcela?>? _suscripcionParcela;
  bool _descartado = false;

  Alerta? _alerta;
  Parcela? _parcela;
  bool _cargando = true;

  bool get cargando => _cargando;
  Alerta? get alerta => _alerta;
  DateTime get ahora => _reloj();

  /// La etapa sale de la parcela (la alerta no la guarda); si la parcela no
  /// se puede leer, se muestra solo el cultivo.
  Parcela? get parcela => _parcela;

  /// "Qué puede hacer hoy": una fila por frase de la medida sugerida.
  List<String> get medidas {
    final texto = _alerta?.medidaSugerida.trim() ?? '';
    if (texto.isEmpty) return const [];
    return texto
        .split(RegExp(r'(?<=\.)\s+'))
        .map((frase) => frase.trim())
        .where((frase) => frase.isNotEmpty)
        .toList();
  }

  void _alRecibir(Alerta? alerta) {
    final primera = _alerta == null && alerta != null;
    _alerta = alerta;
    _cargando = false;
    if (primera) {
      unawaited(_alertas.marcarLeida(alerta));
      _suscripcionParcela = _parcelas.observar(alerta.parcelaId).listen((
        parcela,
      ) {
        _parcela = parcela;
        _avisar();
      }, onError: (Object e) => debugPrint('Parcela de la alerta: $e'));
    }
    _avisar();
  }

  /// "Ya tomé medidas". Se ve al instante aunque no haya señal.
  Future<void> atender() async {
    final alerta = _alerta;
    if (alerta == null || alerta.atendida) return;
    _alerta = alerta.copyWith(atendida: true);
    _avisar();
    await _alertas.marcarAtendida(alerta);
  }

  Future<void> compartir() async {
    final alerta = _alerta;
    if (alerta == null) return;
    await _compartir.compartirTexto(Textos.textoCompartir(alerta));
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _suscripcion.cancel();
    _suscripcionParcela?.cancel();
    super.dispose();
  }
}
