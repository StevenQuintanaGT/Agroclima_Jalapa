import 'package:flutter/foundation.dart';

import '../../repositorios/auth_repositorio.dart';
import '../../servicios/cuenta_servicio.dart';
import '../../utilidades/errores.dart';
import '../../utilidades/validadores.dart';

/// Estado de la pantalla de registro (HU-01). Lo escrito se conserva si algo
/// falla (criterio de error: "no se pierde lo escrito").
class RegistroVm extends ChangeNotifier {
  RegistroVm(this._cuenta);

  final CuentaServicio _cuenta;

  String _nombre = '';
  String _telefono = '';
  String _correo = '';
  String _contrasena = '';
  String _repetir = '';
  bool _aceptaTerminos = false;
  bool _intentoEnviar = false;
  bool _cargando = false;
  String? _errorGeneral;
  bool _descartado = false;

  bool get aceptaTerminos => _aceptaTerminos;
  bool get cargando => _cargando;

  /// Error que no es de un campo (sin señal, correo ya usado…).
  String? get errorGeneral => _errorGeneral;

  // Los errores de campo se muestran después del primer intento de enviar;
  // antes solo se confirma lo que va bien (validación positiva del diseño).
  String? get errorNombre =>
      _intentoEnviar ? Validadores.nombre(_nombre) : null;
  String? get errorTelefono =>
      _intentoEnviar ? Validadores.telefono(_telefono) : null;
  String? get errorCorreo =>
      _intentoEnviar ? Validadores.correo(_correo) : null;
  String? get errorContrasena =>
      _intentoEnviar ? Validadores.contrasena(_contrasena) : null;
  String? get errorRepetir => _intentoEnviar
      ? Validadores.repetirContrasena(_repetir, _contrasena)
      : null;

  bool get nombreValido =>
      _nombre.isNotEmpty && Validadores.nombre(_nombre) == null;
  bool get telefonoValido => Validadores.soloDigitos(_telefono).length == 8;
  bool get correoValido =>
      _correo.isNotEmpty && Validadores.correo(_correo) == null;
  bool get contrasenaValida => Validadores.contrasena(_contrasena) == null;
  bool get repetirValida =>
      _repetir.isNotEmpty &&
      contrasenaValida &&
      Validadores.repetirContrasena(_repetir, _contrasena) == null;

  /// El botón se habilita al aceptar los términos (reglas de validación).
  bool get puedeEnviar => _aceptaTerminos && !_cargando;

  bool get _formularioValido =>
      Validadores.nombre(_nombre) == null &&
      Validadores.telefono(_telefono) == null &&
      Validadores.correo(_correo) == null &&
      Validadores.contrasena(_contrasena) == null &&
      Validadores.repetirContrasena(_repetir, _contrasena) == null;

  void cambiarNombre(String valor) => _cambiar(() => _nombre = valor);
  void cambiarTelefono(String valor) => _cambiar(() => _telefono = valor);
  void cambiarCorreo(String valor) => _cambiar(() => _correo = valor);
  void cambiarContrasena(String valor) => _cambiar(() => _contrasena = valor);
  void cambiarRepetir(String valor) => _cambiar(() => _repetir = valor);
  void cambiarTerminos(bool valor) => _cambiar(() => _aceptaTerminos = valor);

  void _cambiar(void Function() cambio) {
    cambio();
    _errorGeneral = null;
    _avisar();
  }

  /// Crea la cuenta. Devuelve `true` si quedó creada.
  Future<bool> registrar() async {
    _intentoEnviar = true;
    _errorGeneral = null;
    if (!_formularioValido || !puedeEnviar) {
      _avisar();
      return false;
    }
    _cargando = true;
    _avisar();
    try {
      await _cuenta.registrar(
        nombre: _nombre.trim(),
        telefono: Validadores.telefonoConCodigo(_telefono),
        correo: _correo.trim(),
        contrasena: _contrasena,
      );
      return true;
    } on ErrorAcceso catch (error) {
      _errorGeneral = Errores.deAcceso(error.codigo);
      return false;
    } catch (error) {
      debugPrint('Registro falló: $error');
      _errorGeneral = Errores.deAcceso('desconocido');
      return false;
    } finally {
      _cargando = false;
      _avisar();
    }
  }

  // Al crear la cuenta la guarda de sesión cambia de pantalla y este VM se
  // descarta mientras aún termina de guardar el perfil.
  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
