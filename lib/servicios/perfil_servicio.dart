import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/usuario.dart';
import '../repositorios/auth_repositorio.dart';
import '../repositorios/usuario_repositorio.dart';

/// Perfil del productor en vivo y sus ajustes (pantallas 28 y 29). Lo
/// escucha la raíz de la app para el tema oscuro y las unidades, y el clima
/// para el ahorro de datos (Observador). Sin sesión, los valores por defecto.
class PerfilServicio extends ChangeNotifier {
  PerfilServicio({required this._auth, required this._usuarios}) {
    _sesion = _auth.cambiosDeSesion.listen(_seguir);
    _seguir(_auth.uidActual);
  }

  final AuthRepositorio _auth;
  final UsuarioRepositorio _usuarios;
  late final StreamSubscription<String?> _sesion;
  StreamSubscription<Usuario?>? _perfil;
  String? _uid;
  Usuario? _usuario;

  /// `null` sin sesión o mientras llega el perfil.
  Usuario? get usuario => _usuario;
  bool get temaOscuro => _usuario?.temaOscuro ?? false;
  bool get fahrenheit => _usuario?.fahrenheit ?? false;
  bool get hectareas => _usuario?.hectareas ?? false;
  bool get ahorroDatos => _usuario?.ahorroDatos ?? false;

  void _seguir(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _perfil?.cancel();
    _perfil = null;
    _usuario = null;
    notifyListeners();
    if (uid == null) return;
    _perfil = _usuarios.observarPerfil(uid).listen(
      (usuario) {
        _usuario = usuario;
        notifyListeners();
      },
      // Al cerrar sesión la lectura puede rechazarse antes de cancelar.
      onError: (Object error) => debugPrint('Perfil no disponible: $error'),
    );
  }

  // Los cambios se guardan en el teléfono al instante y Firestore avisa al
  // perfil en vivo, así que se ven aunque no haya señal.

  Future<void> cambiarFahrenheit(bool valor) =>
      _ajustar(unidadTemperatura: valor ? 'F' : 'C');

  Future<void> cambiarHectareas(bool valor) =>
      _ajustar(unidadArea: valor ? 'hectarea' : 'manzana');

  Future<void> cambiarTemaOscuro(bool valor) => _ajustar(temaOscuro: valor);

  Future<void> cambiarAhorroDatos(bool valor) => _ajustar(ahorroDatos: valor);

  /// Nombre y teléfono (ya con código de país o vacío). El correo no cambia.
  Future<void> guardarDatos({
    required String nombre,
    required String telefono,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _usuarios.guardarDatos(uid, nombre: nombre, telefono: telefono);
  }

  Future<void> _ajustar({
    String? unidadTemperatura,
    String? unidadArea,
    bool? temaOscuro,
    bool? ahorroDatos,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _usuarios.guardarAjustes(
      uid,
      unidadTemperatura: unidadTemperatura,
      unidadArea: unidadArea,
      temaOscuro: temaOscuro,
      ahorroDatos: ahorroDatos,
    );
  }

  @override
  void dispose() {
    _sesion.cancel();
    _perfil?.cancel();
    super.dispose();
  }
}
