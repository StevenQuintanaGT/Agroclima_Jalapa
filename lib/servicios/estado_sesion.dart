import 'dart:async';

import 'package:flutter/foundation.dart';

import '../repositorios/auth_repositorio.dart';

/// ¿Hay sesión? Lo escucha el enrutador para su guarda (Observador).
/// Arranca con la sesión que Firebase restauró al abrir la app (HU-02).
class EstadoSesion extends ValueNotifier<bool> {
  EstadoSesion(AuthRepositorio auth) : super(auth.uidActual != null) {
    _suscripcion = auth.cambiosDeSesion.listen((uid) => value = uid != null);
  }

  late final StreamSubscription<String?> _suscripcion;

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }
}
