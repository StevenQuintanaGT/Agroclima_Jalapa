import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';

/// "Buscar aldea o lugar" (pantalla 12) con el geocodificador del teléfono:
/// gratis y sin clave (DECISIONES D-34). Si no encuentra, el productor mueve
/// el pin a mano.
class BusquedaLugaresServicio {
  static const _idioma = Locale('es', 'GT');

  // Se crea al primer uso: necesita el plugin nativo.
  Geocoding? _geocoding;

  /// Coordenadas del primer resultado, o `null` si no se encontró. Se agrega
  /// "Jalapa, Guatemala" para no traer lugares de otro país con el mismo nombre.
  Future<({double latitud, double longitud})?> buscar(String lugar) async {
    final texto = lugar.trim();
    if (texto.isEmpty) return null;
    try {
      final geocoding = _geocoding ??= Geocoding();
      final resultados = await geocoding.locationFromAddress(
        '$texto, Jalapa, Guatemala',
        locale: _idioma,
      );
      if (resultados.isEmpty) return null;
      return (
        latitud: resultados.first.latitude,
        longitud: resultados.first.longitude,
      );
    } catch (error) {
      debugPrint('Búsqueda de lugar sin resultado: $error');
      return null;
    }
  }
}
