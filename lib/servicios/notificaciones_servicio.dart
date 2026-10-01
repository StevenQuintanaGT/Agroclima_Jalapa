import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Avisos push (FCM), parte base de HU-02: permiso y token del teléfono.
/// Los canales y la apertura del detalle llegan con HU-10/HU-11.
class NotificacionesServicio {
  NotificacionesServicio({this._mensajeria});

  final FirebaseMessaging? _mensajeria;

  FirebaseMessaging get _fcm => _mensajeria ?? FirebaseMessaging.instance;

  /// Muestra el diálogo del sistema (Android 13+). Se llama solo desde la
  /// pantalla 09, después de explicar para qué sirve (RNF-05).
  Future<bool> pedirPermiso() async {
    final ajustes = await _fcm.requestPermission();
    return ajustes.authorizationStatus == AuthorizationStatus.authorized ||
        ajustes.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Token de este teléfono, o `null` si no se pudo obtener (sin señal,
  /// sin servicios de Google). No requiere el permiso de avisos.
  Future<String?> obtenerToken() async {
    try {
      return await _fcm.getToken();
    } catch (error) {
      debugPrint('No se obtuvo el token de avisos: $error');
      return null;
    }
  }

  /// FCM cambia el token de vez en cuando; hay que volver a guardarlo.
  Stream<String> get tokenRenovado => _fcm.onTokenRefresh;

  Future<void> borrarToken() async {
    try {
      await _fcm.deleteToken();
    } catch (error) {
      debugPrint('No se borró el token de avisos: $error');
    }
  }
}
