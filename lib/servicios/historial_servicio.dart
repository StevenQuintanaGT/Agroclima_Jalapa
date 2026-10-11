import '../modelos/alerta.dart';
import '../modelos/enums.dart';
import '../modelos/registro_dia.dart';
import '../repositorios/historial_repositorio.dart';
import '../utilidades/fechas.dart';

/// Un día del historial con sus avisos (HU-13).
class DiaHistorial {
  const DiaHistorial({
    required this.registro,
    this.avisos = 0,
    this.nivelAviso,
  });

  final RegistroDia registro;

  /// Avisos con día del evento ese día, y el nivel más alto entre ellos.
  final int avisos;
  final NivelSeveridad? nivelAviso;

  /// Día con lluvia: 1 mm o más (Zhang et al., 2011; igual que el motor).
  bool get conLluvia => (registro.precipitacion ?? 0) >= 1;
}

/// Filtros de la pantalla 26.
enum FiltroHistorial { todo, conLluvia, conAviso }

/// Historial día por día (CO-16, HU-13): solo datos ya guardados.
class HistorialServicio {
  HistorialServicio(this._repositorio);

  final HistorialRepositorio _repositorio;

  /// Días que se piden por vez (plans/05: paginación de 30 días).
  static const int diasPorPagina = 30;

  Stream<List<RegistroDia>> dias(String parcelaId, {required int limite}) =>
      _repositorio.dias(parcelaId, limite: limite);

  /// Junta cada día con los avisos de la parcela de ese día.
  static List<DiaHistorial> conAvisos(
    List<RegistroDia> registros,
    List<Alerta> alertasDeLaParcela,
  ) {
    // Por día, un aviso por tipo de riesgo con su nivel más alto (si el riesgo
    // empeoró, el ciclo creó dos alertas: cuentan como una, UMBRALES.md §5).
    final porDia = <String, Map<TipoRiesgo, NivelSeveridad>>{};
    for (final alerta in alertasDeLaParcela) {
      final tipos = porDia.putIfAbsent(
        Fechas.idDiario(alerta.fechaEvento),
        () => {},
      );
      final otro = tipos[alerta.tipoRiesgo];
      if (otro == null || alerta.nivel.index > otro.index) {
        tipos[alerta.tipoRiesgo] = alerta.nivel;
      }
    }
    return [
      for (final registro in registros)
        DiaHistorial(
          registro: registro,
          avisos: porDia[registro.fecha]?.length ?? 0,
          nivelAviso: porDia[registro.fecha]?.values.reduce(
            (a, b) => a.index >= b.index ? a : b,
          ),
        ),
    ];
  }

  static List<DiaHistorial> filtrar(
    List<DiaHistorial> dias,
    FiltroHistorial filtro,
  ) => switch (filtro) {
    FiltroHistorial.todo => dias,
    FiltroHistorial.conLluvia => dias.where((d) => d.conLluvia).toList(),
    FiltroHistorial.conAviso => dias.where((d) => d.avisos > 0).toList(),
  };
}
