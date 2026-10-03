import 'package:shared_preferences/shared_preferences.dart';

import 'preferencias_locales_repositorio.dart';

/// [PreferenciasLocalesRepositorio] con `shared_preferences`.
class SharedPreferencesLocalesRepositorio
    implements PreferenciasLocalesRepositorio {
  SharedPreferencesLocalesRepositorio._(this._prefs);

  static const _claveBienvenida = 'bienvenidaVista';
  static const _clavePermisos = 'permisosOfrecidos';
  static const _claveParcela = 'parcelaSeleccionada';

  final SharedPreferencesWithCache _prefs;

  /// Carga las marcas al abrir la app, antes de mostrar la primera pantalla.
  static Future<SharedPreferencesLocalesRepositorio> crear() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {_claveBienvenida, _clavePermisos, _claveParcela},
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

  @override
  String? get parcelaSeleccionada => _prefs.getString(_claveParcela);

  @override
  Future<void> elegirParcela(String parcelaId) =>
      _prefs.setString(_claveParcela, parcelaId);
}
