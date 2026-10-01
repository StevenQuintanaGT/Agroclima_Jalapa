import 'package:shared_preferences/shared_preferences.dart';

import 'preferencias_locales_repositorio.dart';

/// [PreferenciasLocalesRepositorio] con `shared_preferences`.
class SharedPreferencesLocalesRepositorio
    implements PreferenciasLocalesRepositorio {
  SharedPreferencesLocalesRepositorio._(this._prefs);

  static const _claveBienvenida = 'bienvenidaVista';
  static const _clavePermisos = 'permisosOfrecidos';

  final SharedPreferencesWithCache _prefs;

  /// Carga las marcas al abrir la app, antes de mostrar la primera pantalla.
  static Future<SharedPreferencesLocalesRepositorio> crear() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {_claveBienvenida, _clavePermisos},
      ),
    );
    return SharedPreferencesLocalesRepositorio._(prefs);
  }

  @override
  bool get bienvenidaVista => _prefs.getBool(_claveBienvenida) ?? false;

  @override
  Future<void> marcarBienvenidaVista() =>
      _prefs.setBool(_claveBienvenida, true);

  @override
  bool get permisosOfrecidos => _prefs.getBool(_clavePermisos) ?? false;

  @override
  Future<void> marcarPermisosOfrecidos() =>
      _prefs.setBool(_clavePermisos, true);
}
