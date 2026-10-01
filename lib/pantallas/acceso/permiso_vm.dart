import 'package:flutter/foundation.dart';

import '../../repositorios/preferencias_locales_repositorio.dart';

/// Pantallas 08 y 09: explicar el permiso y, si el productor acepta, pedir
/// el del sistema. "Ahora no" continúa sin pedir nada (RNF-05).
class PermisoVm extends ChangeNotifier {
  PermisoVm({
    required this._pedirPermiso,
    required this._preferencias,
    required this.esUltimo,
  });

  final Future<bool> Function() _pedirPermiso;
  final PreferenciasLocalesRepositorio _preferencias;

  /// La de avisos es la última: al terminarla ya no se vuelven a ofrecer.
  final bool esUltimo;

  bool _pidiendo = false;
  bool _descartado = false;

  bool get pidiendo => _pidiendo;

  /// "Permitir": muestra el diálogo del sistema. Sea cual sea la respuesta,
  /// se continúa (no se bloquea al productor).
  Future<void> permitir() async {
    if (_pidiendo) return;
    _pidiendo = true;
    _avisar();
    try {
      await _pedirPermiso();
    } catch (error) {
      debugPrint('No se pudo pedir el permiso: $error');
    } finally {
      _pidiendo = false;
      _avisar();
    }
    await _terminar();
  }

  Future<void> ahoraNo() => _terminar();

  Future<void> _terminar() async {
    if (esUltimo) await _preferencias.marcarPermisosOfrecidos();
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
