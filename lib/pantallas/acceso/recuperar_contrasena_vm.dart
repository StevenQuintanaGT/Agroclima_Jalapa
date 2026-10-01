import 'package:flutter/foundation.dart';

import '../../repositorios/auth_repositorio.dart';
import '../../servicios/cuenta_servicio.dart';
import '../../utilidades/errores.dart';
import '../../utilidades/validadores.dart';

/// Estado de "Recuperar contraseña" (pantalla 07). La confirmación se
/// muestra en la misma pantalla.
class RecuperarContrasenaVm extends ChangeNotifier {
  RecuperarContrasenaVm(this._cuenta);

  final CuentaServicio _cuenta;

  String _correo = '';
  bool _intentoEnviar = false;
  bool _enviando = false;
  bool _enviado = false;
  String? _errorGeneral;
  bool _descartado = false;

  bool get enviando => _enviando;
  bool get enviado => _enviado;
  String? get errorGeneral => _errorGeneral;
  String? get errorCorreo =>
      _intentoEnviar ? Validadores.correo(_correo) : null;
  bool get correoValido =>
      _correo.isNotEmpty && Validadores.correo(_correo) == null;

  void cambiarCorreo(String valor) {
    _correo = valor;
    _errorGeneral = null;
    _avisar();
  }

  Future<void> enviar() async {
    _intentoEnviar = true;
    _errorGeneral = null;
    if (_enviando || Validadores.correo(_correo) != null) {
      _avisar();
      return;
    }
    _enviando = true;
    _avisar();
    try {
      await _cuenta.recuperarContrasena(_correo.trim());
      _enviado = true;
    } on ErrorAcceso catch (error) {
      _errorGeneral = Errores.deAcceso(error.codigo);
    } catch (error) {
      debugPrint('Recuperar contraseña falló: $error');
      _errorGeneral = Errores.deAcceso('desconocido');
    } finally {
      _enviando = false;
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
