import '../config/constantes.dart';
import '../modelos/franja_pronostico.dart';
import '../modelos/pronostico_dia.dart';
import '../utilidades/fechas.dart';

/// Convierte las franjas de 3 h en un pronóstico por día, agrupadas en hora
/// de Guatemala (DECISIONES D-10). Es la misma cuenta que hace el ciclo de la
/// nube (`functions/src/pronostico_diario.js`).
class PronosticoDiario {
  PronosticoDiario._();

  /// Los primeros [Constantes.diasPronostico] días (hoy incluido), en orden.
  static List<PronosticoDia> agrupar(List<FranjaPronostico> franjas) {
    final porDia = <String, List<FranjaPronostico>>{};
    for (final franja in franjas) {
      porDia
          .putIfAbsent(Fechas.idDiario(franja.fechaHora), () => [])
          .add(franja);
    }
    final dias = porDia.keys.toList()..sort();
    return [
      for (final dia in dias.take(Constantes.diasPronostico))
        _resumir(dia, porDia[dia]!),
    ];
  }

  static PronosticoDia _resumir(String fecha, List<FranjaPronostico> franjas) {
    double minimo(double Function(FranjaPronostico) valor) =>
        franjas.map(valor).reduce((a, b) => a < b ? a : b);
    double maximo(double Function(FranjaPronostico) valor) =>
        franjas.map(valor).reduce((a, b) => a > b ? a : b);
    double suma(double Function(FranjaPronostico) valor) =>
        franjas.map(valor).fold(0, (a, b) => a + b);
    return PronosticoDia(
      fecha: fecha,
      temperaturaMinima: _redondear(minimo((f) => f.temperaturaMinima)),
      temperaturaMaxima: _redondear(maximo((f) => f.temperaturaMaxima)),
      precipitacionHora: _redondear(maximo((f) => f.lluviaPorHora)),
      acumuladoDia: _redondear(suma((f) => f.lluvia3h)),
      velocidadViento: _redondear(maximo((f) => f.velocidadViento)),
      humedadRelativa: _redondear(
        suma((f) => f.humedadRelativa) / franjas.length,
      ),
    );
  }

  /// Dos decimales bastan y evitan arrastrar errores de punto flotante.
  static double _redondear(double valor) => (valor * 100).round() / 100;
}
