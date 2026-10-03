import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../modelos/parcela.dart';
import '../../servicios/parcelas_servicio.dart';
import 'mis_parcelas_vm.dart';

/// Detalle de una parcela (pantalla 15, HU-06), en vivo: si se edita o se
/// borra desde otro teléfono, la pantalla se entera.
class DetalleParcelaVm extends ChangeNotifier {
  DetalleParcelaVm(this._parcelas, this.parcelaId) {
    _suscripcion = _parcelas
        .observar(parcelaId)
        .listen(
          (parcela) {
            _parcela = parcela;
            _cargando = false;
            _avisar();
          },
          onError: (Object error) {
            debugPrint('No se pudo leer la parcela: $error');
            _cargando = false;
            _avisar();
          },
        );
  }

  final ParcelasServicio _parcelas;
  final String parcelaId;
  late final StreamSubscription<Parcela?> _suscripcion;
  bool _descartado = false;

  Parcela? _parcela;
  bool _cargando = true;
  bool _borrando = false;
  bool _borrada = false;

  Parcela? get parcela => _parcela;
  bool get cargando => _cargando;
  bool get borrando => _borrando;

  /// Se borró desde esta pantalla: ya se va a cerrar.
  bool get borrada => _borrada;

  /// Ya no existe (borrada, o el enlace es viejo).
  bool get noExiste =>
      !_cargando && _parcela == null && !_borrando && !_borrada;

  Future<ResultadoBorrado> borrar() async {
    if (_borrando) return ResultadoBorrado.error;
    _borrando = true;
    _avisar();
    final resultado = await borrarParcela(_parcelas, parcelaId);
    _borrando = false;
    _borrada = resultado != ResultadoBorrado.error;
    _avisar();
    return resultado;
  }

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
