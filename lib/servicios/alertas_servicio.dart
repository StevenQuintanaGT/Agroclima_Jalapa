import '../modelos/alerta.dart';
import '../repositorios/alertas_repositorio.dart';
import '../repositorios/auth_repositorio.dart';
import '../utilidades/fechas.dart';

/// Lógica del centro de alertas (CO-14, HU-11): qué alertas están activas,
/// cuáles ya pasaron y en qué orden se muestran.
class AlertasServicio {
  AlertasServicio({required this._repositorio, required this._auth});

  final AlertasRepositorio _repositorio;
  final AuthRepositorio _auth;

  /// Alertas del productor con sesión, en vivo (las más recientes, hasta
  /// [limite]). Vacío si no hay sesión.
  Stream<List<Alerta>> misAlertas({int? limite}) {
    final uid = _auth.uidActual;
    if (uid == null) return Stream.value(const []);
    return limite == null
        ? _repositorio.delUsuario(uid)
        : _repositorio.delUsuario(uid, limite: limite);
  }

  /// Parcelas que aparecen en las alertas (para el filtro del historial,
  /// HU-14), en orden alfabético: (parcelaId, nombre).
  static List<(String, String)> parcelasDe(List<Alerta> alertas) {
    final nombres = <String, String>{};
    for (final alerta in alertas) {
      nombres.putIfAbsent(alerta.parcelaId, () => alerta.parcelaNombre);
    }
    return [for (final e in nombres.entries) (e.key, e.value)]
      ..sort((a, b) => a.$2.compareTo(b.$2));
  }

  Stream<Alerta?> observar(String alertaId) => _repositorio.observar(alertaId);

  Future<void> marcarLeida(Alerta alerta) async {
    if (!alerta.leida) await _repositorio.marcarLeida(alerta.alertaId);
  }

  Future<void> marcarAtendida(Alerta alerta) async {
    if (!alerta.atendida) await _repositorio.marcarAtendida(alerta.alertaId);
  }

  /// Activas = el día del evento es hoy o después (plans/04 HU-11). PELIGRO
  /// primero y, dentro de cada nivel, lo más cercano primero.
  static List<Alerta> activas(List<Alerta> alertas, DateTime ahora) {
    final hoy = Fechas.idDiario(ahora);
    return _sinRepetir(
      alertas.where((a) => Fechas.idDiario(a.fechaEvento).compareTo(hoy) >= 0),
    )..sort(
      (a, b) => b.nivel.index != a.nivel.index
          ? b.nivel.index.compareTo(a.nivel.index)
          : a.fechaEvento.compareTo(b.fechaEvento),
    );
  }

  /// Anteriores = el día del evento ya pasó; lo más reciente primero.
  static List<Alerta> anteriores(List<Alerta> alertas, DateTime ahora) {
    final hoy = Fechas.idDiario(ahora);
    return _sinRepetir(
      alertas.where((a) => Fechas.idDiario(a.fechaEvento).compareTo(hoy) < 0),
    )..sort((a, b) => b.fechaEvento.compareTo(a.fechaEvento));
  }

  /// Número del distintivo rojo: activas sin abrir.
  static int sinLeer(List<Alerta> alertas, DateTime ahora) =>
      activas(alertas, ahora).where((a) => !a.leida).length;

  /// Si el riesgo de un día empeoró, el ciclo creó otra alerta de nivel
  /// mayor (UMBRALES.md §5): se muestra solo la de nivel más alto.
  static List<Alerta> _sinRepetir(Iterable<Alerta> alertas) {
    final porEvento = <String, Alerta>{};
    for (final alerta in alertas) {
      final clave =
          '${alerta.parcelaId}|${alerta.tipoRiesgo.valor}|'
          '${Fechas.idDiario(alerta.fechaEvento)}';
      final otra = porEvento[clave];
      if (otra == null || alerta.nivel.index > otra.nivel.index) {
        porEvento[clave] = alerta;
      }
    }
    return porEvento.values.toList();
  }
}
