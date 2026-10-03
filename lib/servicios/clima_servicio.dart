import '../modelos/clima_actual.dart';
import '../modelos/condicion.dart';
import '../modelos/franja_pronostico.dart';
import '../modelos/parcela.dart';
import '../modelos/pronostico_dia.dart';
import '../modelos/resultado.dart';
import '../repositorios/clima_repositorio.dart';
import '../utilidades/fechas.dart';
import 'pronostico_diario.dart';

/// Casos de uso del clima de una parcela (MOD-03): lo que necesita el panel.
class ClimaServicio {
  ClimaServicio(this._repositorio);

  final ClimaRepositorio _repositorio;

  /// Cuántas franjas de 3 h mira "Va a llover" (las próximas 12 horas).
  static const int franjasProximas = 4;

  Future<Resultado<ClimaActual>> actual(
    Parcela parcela, {
    bool forzar = false,
  }) => _repositorio.actual(parcela, forzar: forzar);

  Future<Resultado<List<FranjaPronostico>>> porHoras(
    Parcela parcela, {
    bool forzar = false,
  }) => _repositorio.porHoras(parcela, forzar: forzar);

  Stream<Condicion?> condicionDeHoy(String parcelaId) =>
      _repositorio.condicionDeHoy(parcelaId);

  Stream<List<PronosticoDia>> proximosDias(String parcelaId) =>
      _repositorio.proximosDias(parcelaId);

  /// Resumen de hoy (máxima y mínima): el que guardó el ciclo para todo el
  /// día o, si todavía no hay, el que se calcula con las franjas del teléfono.
  /// El pronóstico solo mira lo que falta del día, así que la temperatura de
  /// [actual] también cuenta (la máxima nunca queda por debajo de la de ahora).
  static PronosticoDia? hoy({
    required List<PronosticoDia> guardados,
    required List<FranjaPronostico> franjas,
    required DateTime ahora,
    ClimaActual? actual,
  }) {
    final idHoy = Fechas.idDiario(ahora);
    PronosticoDia? dia;
    for (final guardado in guardados) {
      if (guardado.fecha == idHoy) dia = guardado;
    }
    if (dia == null) {
      for (final calculado in PronosticoDiario.agrupar(franjas)) {
        if (calculado.fecha == idHoy) dia = calculado;
      }
    }
    if (dia == null || actual == null) return dia;
    final temperatura = actual.temperatura;
    return PronosticoDia(
      fecha: dia.fecha,
      temperaturaMinima: temperatura < dia.temperaturaMinima
          ? temperatura
          : dia.temperaturaMinima,
      temperaturaMaxima: temperatura > dia.temperaturaMaxima
          ? temperatura
          : dia.temperaturaMaxima,
      precipitacionHora: dia.precipitacionHora,
      acumuladoDia: dia.acumuladoDia,
      velocidadViento: dia.velocidadViento,
      humedadRelativa: dia.humedadRelativa,
      fechaConsulta: dia.fechaConsulta,
    );
  }

  /// Probabilidad de lluvia (0 a 1) en las próximas 12 horas; `null` sin
  /// pronóstico.
  static double? probabilidadLluvia(
    List<FranjaPronostico> franjas,
    DateTime ahora,
  ) {
    final proximas = franjas
        .where((f) => f.fechaHora.add(const Duration(hours: 3)).isAfter(ahora))
        .take(franjasProximas);
    if (proximas.isEmpty) return null;
    return proximas
        .map((f) => f.probabilidadLluvia)
        .reduce((a, b) => a > b ? a : b);
  }
}
