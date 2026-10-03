import 'package:flutter/foundation.dart';

import '../../servicios/cuenta_servicio.dart';

/// Estado del perfil. Por ahora solo "Cerrar sesión" (HU-02); el resto del
/// perfil se completa en la Etapa 6.
class PerfilVm extends ChangeNotifier {
  PerfilVm(this._cuenta);

  final CuentaServicio _cuenta;
  bool _cerrando = false;
  bool _descartado = false;

  bool get cerrando => _cerrando;

  Future<void> cerrarSesion() async {
    if (_cerrando) return;
    _cerrando = true;
    _avisar();
    try {
      await _cuenta.cerrarSesion();
    } catch (error) {
      debugPrint('Cerrar sesión falló: $error');
    } finally {
      _cerrando = false;
      _avisar();
    }
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
