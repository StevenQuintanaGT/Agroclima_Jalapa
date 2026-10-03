import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Resultado de pedir la posición del teléfono.
sealed class ResultadoUbicacion {
  const ResultadoUbicacion();
}

class UbicacionEncontrada extends ResultadoUbicacion {
  const UbicacionEncontrada({
    required this.latitud,
    required this.longitud,
    this.altitud,
  });

  final double latitud;
  final double longitud;

  /// Metros sobre el nivel del mar, si el GPS la dio.
  final int? altitud;
}

/// El productor no dio permiso: puede seguir con el mapa (plans/02).
class UbicacionSinPermiso extends ResultadoUbicacion {
  const UbicacionSinPermiso();
}

/// La ubicación del teléfono está apagada.
class UbicacionApagada extends ResultadoUbicacion {
  const UbicacionApagada();
}

/// No se obtuvo (sin señal de GPS, tiempo agotado…).
class UbicacionNoDisponible extends ResultadoUbicacion {
  const UbicacionNoDisponible();
}

/// Ubicación del teléfono (HU-04). No guarda la posición del teléfono en
/// ningún lado: solo se usa para poner el pin de la parcela (RO-04).
class UbicacionServicio {
  /// Muestra el diálogo del sistema. Se llama desde la pantalla 08, después
  /// de explicar para qué sirve (RNF-05).
  Future<bool> pedirPermiso() async {
    final estado = await Permission.locationWhenInUse.request();
    return estado.isGranted || estado.isLimited;
  }

  /// Posición actual. Si aún no hay permiso lo pide, porque el productor
  /// tocó "Usar mi ubicación" (sabe para qué es).
  Future<ResultadoUbicacion> posicionActual() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const UbicacionApagada();
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return const UbicacionSinPermiso();
      }
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return UbicacionEncontrada(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
        // Sin dato el GPS da 0; no se inventa una altura.
        altitud: posicion.altitude > 0 ? posicion.altitude.round() : null,
      );
    } catch (error) {
      debugPrint('No se obtuvo la ubicación: $error');
      return const UbicacionNoDisponible();
    }
  }
}
