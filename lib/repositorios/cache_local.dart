import 'package:shared_preferences/shared_preferences.dart';

/// Textos guardados solo en el teléfono, para la caché del clima (D-12).
abstract class CacheLocal {
  Future<String?> leer(String clave);
  Future<void> guardar(String clave, String valor);
}

/// [CacheLocal] con `shared_preferences`.
class SharedPreferencesCacheLocal implements CacheLocal {
  SharedPreferencesCacheLocal([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> leer(String clave) => _prefs.getString(clave);

  @override
  Future<void> guardar(String clave, String valor) =>
      _prefs.setString(clave, valor);
}
