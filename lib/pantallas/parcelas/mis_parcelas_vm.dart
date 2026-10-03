import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../modelos/parcela.dart';
import '../../servicios/parcelas_servicio.dart';

/// Resultado de borrar, para que la pantalla sepa qué decir.
enum ResultadoBorrado { borrada, borradaSinSenal, error }

/// "Mis parcelas" (pantallas 14 y 16, HU-06): lista en vivo de las parcelas
/// del productor, también sin señal (copia local de Firestore).
class MisParcelasVm extends ChangeNotifier {
  MisParcelasVm(this._parcelas) {
    _escuchar();
  }

  final ParcelasServicio _parcelas;
  StreamSubscription<List<Parcela>>? _suscripcion;
  bool _descartado = false;

  List<Parcela> _lista = const [];
  bool _cargando = true;
  bool _error = false;

  List<Parcela> get parcelas => _lista;
  bool get cargando => _cargando;
  bool get error => _error;
  bool get vacia => !_cargando && !_error && _lista.isEmpty;

  void reintentar() {
    _cargando = true;
    _error = false;
    _avisar();
    _escuchar();
  }

  /// Borra la parcela (después de que el productor confirmó).
  Future<ResultadoBorrado> borrar(Parcela parcela) =>
      borrarParcela(_parcelas, parcela.parcelaId);

  void _escuchar() {
    _suscripcion?.cancel();
    _suscripcion = _parcelas.misParcelas().listen(
      (lista) {
        _lista = lista;
        _cargando = false;
        _error = false;
        _avisar();
      },
      onError: (Object error) {
        debugPrint('No se pudieron leer las parcelas: $error');
        _cargando = false;
        _error = true;
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

/// Borrado compartido por la lista y el detalle.
Future<ResultadoBorrado> borrarParcela(
  ParcelasServicio parcelas,
  String parcelaId,
) async {
  try {
    final pendiente = await parcelas.eliminar(parcelaId);
    return pendiente
        ? ResultadoBorrado.borradaSinSenal
        : ResultadoBorrado.borrada;
  } catch (error) {
    debugPrint('Borrar parcela falló: $error');
    return ResultadoBorrado.error;
  }
}
