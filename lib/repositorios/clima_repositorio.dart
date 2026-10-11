import '../modelos/capa_clima.dart';
import '../modelos/clima_actual.dart';
import '../modelos/condicion.dart';
import '../modelos/franja_pronostico.dart';
import '../modelos/parcela.dart';
import '../modelos/pronostico_dia.dart';
import '../modelos/resultado.dart';

/// Contrato del clima de una parcela (CO-07), con la política "caché
/// primero" (RNF-08): primero lo guardado; a la red solo si caducó (D-08) o
/// el productor pidió actualizar; si falla, lo guardado marcado como no
/// vigente. Implementación: `OpenWeatherClimaRepositorio`.
abstract class ClimaRepositorio {
  /// Clima de este momento en la parcela (HU-07).
  Future<Resultado<ClimaActual>> actual(Parcela parcela, {bool forzar = false});

  /// Pronóstico por franjas de 3 h (panel y detalle, HU-08).
  Future<Resultado<List<FranjaPronostico>>> porHoras(
    Parcela parcela, {
    bool forzar = false,
  });

  /// Condición de hoy guardada en la nube (trae la lluvia del día, D-40).
  Stream<Condicion?> condicionDeHoy(String parcelaId);

  /// Pronóstico por día que guardó el ciclo, de hoy en adelante.
  Stream<List<PronosticoDia>> proximosDias(String parcelaId);

  /// Plantilla de teselas de una capa del mapa del clima (HU-09), con
  /// {z}/{x}/{y}. Cambiar de proveedor no toca el mapa (RNF-20).
  String urlCapa(CapaClima capa);
}
