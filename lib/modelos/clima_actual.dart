/// Clima de este momento en un punto, como lo entrega el proveedor ya
/// traducido al dominio (Current Weather 2.5). Unidades métricas: °C, %,
/// mm y km/h. Se guarda en `condiciones` como [Condicion].
class ClimaActual {
  const ClimaActual({
    required this.fechaHora,
    required this.temperatura,
    required this.sensacionTermica,
    required this.humedadRelativa,
    required this.lluviaUltimaHora,
    required this.velocidadViento,
    required this.codigoClima,
    this.descripcion = '',
    this.salidaSol,
    this.puestaSol,
  });

  /// Momento de la observación (UTC).
  final DateTime fechaHora;
  final double temperatura;
  final double sensacionTermica;
  final double humedadRelativa;

  /// mm caídos en la última hora (0 si no llovió).
  final double lluviaUltimaHora;
  final double velocidadViento;

  /// Código de condición del proveedor (p. ej. 500 = lluvia ligera); la app
  /// lo traduce a su propia frase en `Textos`.
  final int codigoClima;
  final String descripcion;
  final DateTime? salidaSol;
  final DateTime? puestaSol;
}
