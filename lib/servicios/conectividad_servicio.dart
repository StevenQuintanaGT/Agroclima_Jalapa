import 'package:connectivity_plus/connectivity_plus.dart';

/// Estado de la conexión del teléfono (HU-15). Solo dice si hay alguna red
/// (datos o wifi); que haya internet de verdad se sabe al consultar.
class ConectividadServicio {
  ConectividadServicio([Connectivity? conectividad])
    : _conectividad = conectividad ?? Connectivity();

  final Connectivity _conectividad;

  /// `true` cuando hay red; avisa solo cuando cambia.
  Stream<bool> get cambios =>
      _conectividad.onConnectivityChanged.map(_hayRed).distinct();

  Future<bool> hayRed() async =>
      _hayRed(await _conectividad.checkConnectivity());

  static bool _hayRed(List<ConnectivityResult> resultados) =>
      resultados.any((r) => r != ConnectivityResult.none);
}
