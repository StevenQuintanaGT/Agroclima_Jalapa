import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/textos.dart';
import '../modelos/enums.dart';

/// Avisos push (FCM): permiso y token del teléfono (HU-02), canales por nivel,
/// notificación con la app abierta y apertura de la alerta al tocarla (HU-10).
///
/// El ciclo manda cada aviso con su canal (`android.notification.channelId`)
/// y `data: { alertaId, parcelaId, nivel }`. Con la app cerrada o en segundo
/// plano, Android lo muestra solo; con la app abierta lo muestra este servicio.
class NotificacionesServicio {
  NotificacionesServicio({this._mensajeria, this._locales});

  final FirebaseMessaging? _mensajeria;
  final FlutterLocalNotificationsPlugin? _locales;

  FirebaseMessaging get _fcm => _mensajeria ?? FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin get _plugin =>
      _locales ?? FlutterLocalNotificationsPlugin();

  void Function(String alertaId)? _alAbrir;
  String? _pendiente;
  final List<StreamSubscription<RemoteMessage>> _suscripciones = [];

  /// Canales de Android por nivel del semáforo (mismos ids que
  /// `functions/src/notificaciones.js`). PELIGRO con importancia alta.
  static final Map<NivelSeveridad, AndroidNotificationChannel> canales = {
    NivelSeveridad.critica: const AndroidNotificationChannel(
      'alertas_peligro',
      Textos.canalPeligro,
      description: Textos.canalPeligroDetalle,
      importance: Importance.high,
    ),
    NivelSeveridad.preventiva: const AndroidNotificationChannel(
      'alertas_precaucion',
      Textos.canalPrecaucion,
      description: Textos.canalPrecaucionDetalle,
    ),
    NivelSeveridad.informativa: const AndroidNotificationChannel(
      'alertas_normal',
      Textos.canalNormal,
      description: Textos.canalNormalDetalle,
      importance: Importance.low,
    ),
  };

  /// Crea los canales y empieza a escuchar los avisos. Se llama al arrancar;
  /// no pide ningún permiso (RNF-05).
  Future<void> iniciar() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      for (final canal in canales.values) {
        await android?.createNotificationChannel(canal);
      }
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (respuesta) =>
            abrir(respuesta.payload),
      );
      // App abierta desde un aviso mostrado por este servicio.
      final lanzamiento = await _plugin.getNotificationAppLaunchDetails();
      if (lanzamiento?.didNotificationLaunchApp ?? false) {
        abrir(lanzamiento!.notificationResponse?.payload);
      }
      _suscripciones
        ..add(FirebaseMessaging.onMessage.listen(_mostrarEnPrimerPlano))
        ..add(
          FirebaseMessaging.onMessageOpenedApp.listen(
            (mensaje) => abrir(alertaDe(mensaje.data)),
          ),
        );
      // App cerrada y abierta tocando el aviso del sistema.
      final inicial = await _fcm.getInitialMessage();
      if (inicial != null) abrir(alertaDe(inicial.data));
    } catch (error) {
      debugPrint('No se iniciaron los avisos: $error');
    }
  }

  /// Quien navega (la barra inferior, ya con sesión) se registra aquí. Si un
  /// aviso se tocó antes (arranque en frío), se entrega en ese momento.
  void alAbrirAlerta(void Function(String alertaId)? accion) {
    _alAbrir = accion;
    final pendiente = _pendiente;
    if (accion != null && pendiente != null) {
      _pendiente = null;
      accion(pendiente);
    }
  }

  @visibleForTesting
  void abrir(String? alertaId) {
    if (alertaId == null || alertaId.isEmpty) return;
    final accion = _alAbrir;
    if (accion == null) {
      _pendiente = alertaId;
    } else {
      accion(alertaId);
    }
  }

  /// `alertaId` de los datos del aviso, o `null` si no trae.
  static String? alertaDe(Map<String, dynamic> datos) {
    final id = datos['alertaId'];
    return id is String && id.isNotEmpty ? id : null;
  }

  /// Canal del aviso según su nivel; NORMAL si no lo trae.
  static AndroidNotificationChannel canalDe(Map<String, dynamic> datos) =>
      canales[NivelSeveridad.desdeValor(datos['nivel'] as String?)] ??
      canales[NivelSeveridad.informativa]!;

  Future<void> _mostrarEnPrimerPlano(RemoteMessage mensaje) async {
    final aviso = mensaje.notification;
    if (aviso == null) return;
    final canal = canalDe(mensaje.data);
    try {
      await _plugin.show(
        id: (mensaje.messageId ?? '${DateTime.now()}').hashCode & 0x7fffffff,
        title: aviso.title,
        body: aviso.body,
        payload: alertaDe(mensaje.data),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            canal.id,
            canal.name,
            channelDescription: canal.description,
            importance: canal.importance,
            priority: canal.importance == Importance.high
                ? Priority.high
                : Priority.defaultPriority,
            styleInformation: BigTextStyleInformation(aviso.body ?? ''),
          ),
        ),
      );
    } catch (error) {
      debugPrint('No se mostró el aviso: $error');
    }
  }

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
