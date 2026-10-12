import 'package:flutter/foundation.dart';

import '../../servicios/conectividad_servicio.dart';
import '../../servicios/cuenta_servicio.dart';
import '../../servicios/perfil_servicio.dart';

/// Cómo terminó "Eliminar mi cuenta".
enum ResultadoEliminar { hecho, sinSenal }

/// Estado de Ajustes (pantalla 29). Cada cambio se guarda en `usuarios/{uid}`
/// y se ve al instante en toda la app, también sin señal (D-55).
class AjustesVm extends ChangeNotifier {
  AjustesVm({
    required this._perfil,
    required this._cuenta,
    required this._conectividad,
  }) {
    _perfil.addListener(_avisar);
  }

  final PerfilServicio _perfil;
  final CuentaServicio _cuenta;
  final ConectividadServicio _conectividad;
  bool _eliminando = false;
  bool _cerrando = false;
  bool _descartado = false;

  bool get fahrenheit => _perfil.fahrenheit;
  bool get hectareas => _perfil.hectareas;
  bool get temaOscuro => _perfil.temaOscuro;
  bool get ahorroDatos => _perfil.ahorroDatos;
  bool get eliminando => _eliminando;
  bool get cerrando => _cerrando;

  void cambiarFahrenheit(bool valor) =>
      _guardar(() => _perfil.cambiarFahrenheit(valor));
  void cambiarHectareas(bool valor) =>
      _guardar(() => _perfil.cambiarHectareas(valor));
  void cambiarTemaOscuro(bool valor) =>
      _guardar(() => _perfil.cambiarTemaOscuro(valor));
  void cambiarAhorroDatos(bool valor) =>
      _guardar(() => _perfil.cambiarAhorroDatos(valor));

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

  /// Ya confirmó dos veces. Sin señal no se intenta: al cerrar sesión se
  /// borra la copia del teléfono y la solicitud se perdería.
  Future<ResultadoEliminar> eliminarCuenta() async {
    if (_eliminando) return ResultadoEliminar.sinSenal;
    _eliminando = true;
    _avisar();
    try {
      if (!await _conectividad.hayRed()) return ResultadoEliminar.sinSenal;
      await _cuenta.eliminarCuenta();
      return ResultadoEliminar.hecho;
    } catch (error) {
      debugPrint('No se pudo pedir eliminar la cuenta: $error');
      return ResultadoEliminar.sinSenal;
    } finally {
      _eliminando = false;
      _avisar();
    }
  }

  Future<void> _guardar(Future<void> Function() accion) async {
    try {
      await accion();
    } catch (error) {
      debugPrint('No se guardó el ajuste: $error');
    }
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _perfil.removeListener(_avisar);
    super.dispose();
  }
}
