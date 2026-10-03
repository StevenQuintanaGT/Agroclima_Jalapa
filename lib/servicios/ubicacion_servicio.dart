import 'package:permission_handler/permission_handler.dart';

/// Ubicación del teléfono. Por ahora solo el permiso (pantalla 08); la
/// posición para registrar la parcela llega con HU-04.
class UbicacionServicio {
  /// Muestra el diálogo del sistema. Se llama solo desde la pantalla 08,
  /// después de explicar para qué sirve (RNF-05).
  Future<bool> pedirPermiso() async {
    final estado = await Permission.locationWhenInUse.request();
    return estado.isGranted || estado.isLimited;
  }
}
