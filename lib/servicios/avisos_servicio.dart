import '../modelos/enums.dart';
import '../modelos/parcela.dart';
import '../modelos/preferencia_alerta.dart';
import '../modelos/umbral.dart';
import '../repositorios/auth_repositorio.dart';
import '../repositorios/umbrales_repositorio.dart';
import '../repositorios/usuario_repositorio.dart';

/// "Mis avisos" (CO-15, HU-12): qué tipos de aviso suenan, desde qué nivel y
/// si se calla de noche. Las preferencias filtran el envío, no la generación:
/// la alerta siempre queda en la app.
class AvisosServicio {
  AvisosServicio({
    required this._usuarios,
    required this._auth,
    required this._umbrales,
  });

  final UsuarioRepositorio _usuarios;
  final AuthRepositorio _auth;
  final UmbralesRepositorio _umbrales;

  /// Orden en pantalla (diseño 23): primero lo que más daño hace en Jalapa.
  static const List<TipoRiesgo> orden = [
    TipoRiesgo.temperaturaBaja,
    TipoRiesgo.lluviaIntensa,
    TipoRiesgo.sequia,
    TipoRiesgo.vientoFuerte,
    TipoRiesgo.temperaturaAlta,
    TipoRiesgo.humedadAlta,
  ];

  /// Las 6 preferencias en [orden]; si falta alguna en la base (cuenta
  /// vieja), con los valores por defecto.
  Stream<List<PreferenciaAlerta>> misPreferencias() {
    final uid = _auth.uidActual;
    if (uid == null) return Stream.value(completar(const []));
    return _usuarios.observarPreferencias(uid).map(completar);
  }

  static List<PreferenciaAlerta> completar(List<PreferenciaAlerta> guardadas) {
    final porTipo = {for (final p in guardadas) p.tipoRiesgo: p};
    return [
      for (final tipo in orden)
        porTipo[tipo] ?? PreferenciaAlerta.porDefecto(tipo),
    ];
  }

  Future<void> guardar(List<PreferenciaAlerta> lista) async {
    final uid = _auth.uidActual;
    if (uid == null) return;
    await _usuarios.guardarPreferencias(uid, lista);
  }

  /// Enciende o apaga un tipo de aviso.
  static List<PreferenciaAlerta> conActiva(
    List<PreferenciaAlerta> lista,
    TipoRiesgo tipo,
    bool activa,
  ) => [
    for (final p in lista)
      p.tipoRiesgo == tipo ? p.copyWith(activa: activa) : p,
  ];

  /// "Avisarme desde": la pantalla lo elige una vez para todos los tipos.
  static List<PreferenciaAlerta> conNivelMinimo(
    List<PreferenciaAlerta> lista,
    NivelSeveridad nivel,
  ) => [for (final p in lista) p.copyWith(nivelMinimo: nivel)];

  /// "No sonar de noche" para todos los tipos (PELIGRO suena igual).
  static List<PreferenciaAlerta> conSilencio(
    List<PreferenciaAlerta> lista,
    bool activo,
  ) => [
    for (final p in lista)
      p.copyWith(
        silencioDesde: activo ? PreferenciaAlerta.silencioDesdePorDefecto : '',
        silencioHasta: activo ? PreferenciaAlerta.silencioHastaPorDefecto : '',
      ),
  ];

  /// Lo que aguanta cada cultivo de sus parcelas (D-20: se muestra, no se
  /// cambia). Por cada tipo de riesgo, el umbral con que empieza a avisar
  /// (el de nivel más bajo) entre los que aplican a alguna de sus parcelas.
  Future<Map<Cultivo?, List<Umbral>>> loQueAguanta(
    List<Parcela> parcelas,
  ) async {
    final catalogo = await _umbrales.vigentes();
    return limitesPorCultivo(catalogo, parcelas);
  }

  static Map<Cultivo?, List<Umbral>> limitesPorCultivo(
    List<Umbral> catalogo,
    List<Parcela> parcelas,
  ) {
    final cultivos = <Cultivo?>{for (final p in parcelas) p.cultivo};
    final resultado = <Cultivo?, List<Umbral>>{};
    for (final cultivo in cultivos) {
      final etapas = {
        for (final p in parcelas)
          if (p.cultivo == cultivo) p.etapa,
      };
      final porTipo = <TipoRiesgo, Umbral>{};
      for (final umbral in catalogo) {
        if (!etapas.any((etapa) => umbral.aplicaA(cultivo, etapa))) continue;
        final otro = porTipo[umbral.tipoRiesgo];
        if (otro == null || _empiezaAntes(umbral, otro)) {
          porTipo[umbral.tipoRiesgo] = umbral;
        }
      }
      resultado[cultivo] = [
        for (final tipo in orden) ?porTipo[tipo],
      ];
    }
    return resultado;
  }

  /// El que avisa primero: nivel más bajo; a igual nivel, el del cultivo y
  /// el de menos días seguidos.
  static bool _empiezaAntes(Umbral a, Umbral b) {
    if (a.nivel.index != b.nivel.index) return a.nivel.index < b.nivel.index;
    if ((a.cultivo == null) != (b.cultivo == null)) return a.cultivo != null;
    return a.duracionDias < b.duracionDias;
  }
}
