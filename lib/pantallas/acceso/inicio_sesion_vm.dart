import 'package:flutter/foundation.dart';

import '../../config/textos.dart';
import '../../repositorios/auth_repositorio.dart';
import '../../servicios/cuenta_servicio.dart';
import '../../utilidades/errores.dart';
import '../../utilidades/validadores.dart';

/// Estado de la pantalla de inicio de sesión (pantalla 05, HU-02).
class InicioSesionVm extends ChangeNotifier {
  InicioSesionVm(this._cuenta);

  final CuentaServicio _cuenta;

  String _correo = '';
  String _contrasena = '';
  bool _intentoEnviar = false;
  bool _cargando = false;
  bool _cargandoGoogle = false;
  String? _errorGeneral;
  bool _descartado = false;

  bool get cargando => _cargando;
  bool get cargandoGoogle => _cargandoGoogle;
  bool get ocupado => _cargando || _cargandoGoogle;
  String? get errorGeneral => _errorGeneral;

  String? get errorCorreo =>
      _intentoEnviar ? Validadores.correo(_correo) : null;

  // Al entrar no se exige el largo: basta con que no esté vacía.
  String? get errorContrasena => _intentoEnviar && _contrasena.isEmpty
      ? Textos.errorContrasenaVacia
      : null;

  void cambiarCorreo(String valor) => _cambiar(() => _correo = valor);
  void cambiarContrasena(String valor) => _cambiar(() => _contrasena = valor);

  void _cambiar(void Function() cambio) {
    cambio();
    _errorGeneral = null;
    _avisar();
  }

  /// Entra con correo y contraseña. Devuelve `true` si entró.
  Future<bool> entrar() async {
    _intentoEnviar = true;
    _errorGeneral = null;
    if (ocupado || Validadores.correo(_correo) != null || _contrasena.isEmpty) {
      _avisar();
      return false;
    }
    _cargando = true;
    _avisar();
    try {
      await _cuenta.iniciarSesion(
        correo: _correo.trim(),
        contrasena: _contrasena,
      );
      return true;
    } on ErrorAcceso catch (error) {
      _errorGeneral = Errores.deAcceso(error.codigo);
      return false;
    } catch (error) {
      debugPrint('Inicio de sesión falló: $error');
      _errorGeneral = Errores.deAcceso('desconocido');
      return false;
    } finally {
      _cargando = false;
      _avisar();
    }
  }

  /// Entra con Google. Si el productor cierra la ventana no se muestra error.
  Future<bool> entrarConGoogle() async {
    if (ocupado) return false;
    _errorGeneral = null;
    _cargandoGoogle = true;
    _avisar();
    try {
      await _cuenta.iniciarSesionConGoogle();
      return true;
    } on ErrorAcceso catch (error) {
      if (error.codigo != ErrorAcceso.cancelado) {
        _errorGeneral = Errores.deAcceso(error.codigo);
      }
      return false;
    } catch (error) {
      debugPrint('Google falló: $error');
      _errorGeneral = Errores.deAcceso('google-desconocido');
      return false;
    } finally {
      _cargandoGoogle = false;
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
