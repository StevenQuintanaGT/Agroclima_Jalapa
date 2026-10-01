import 'package:flutter/foundation.dart';

import '../../repositorios/preferencias_locales_repositorio.dart';

/// Estado de la bienvenida (pantallas 02–04): paso actual y marca de vista.
class BienvenidaVm extends ChangeNotifier {
  BienvenidaVm(this._preferencias);

  static const int totalPasos = 3;

  final PreferenciasLocalesRepositorio _preferencias;
  int _paso = 0;

  int get paso => _paso;
  bool get esUltimo => _paso == totalPasos - 1;

  void irAPaso(int paso) {
    if (paso == _paso) return;
    _paso = paso.clamp(0, totalPasos - 1);
    notifyListeners();
  }

  /// "Omitir" o "Empezar": no se vuelve a mostrar al abrir la app.
  Future<void> terminar() => _preferencias.marcarBienvenidaVista();
}
