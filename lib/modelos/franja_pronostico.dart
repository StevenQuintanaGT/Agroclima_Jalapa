/// Una franja de 3 horas del pronóstico de 5 días (Forecast 2.5), ya
/// traducida al dominio. Alimenta el "por horas" del panel y el detalle de
/// pronóstico, y se agrupa por día en [PronosticoDia] (D-10).
class FranjaPronostico {
  const FranjaPronostico({
    required this.fechaHora,
    required this.temperatura,
    required this.temperaturaMinima,
    required this.temperaturaMaxima,
    required this.humedadRelativa,
    required this.lluvia3h,
    required this.velocidadViento,
    required this.codigoClima,
    this.probabilidadLluvia = 0,
    this.descripcion = '',
  });

  /// Inicio de la franja (UTC).
  final DateTime fechaHora;
  final double temperatura;
  final double temperaturaMinima;
  final double temperaturaMaxima;
  final double humedadRelativa;

  /// mm esperados en las 3 horas (0 si no se espera lluvia).
  final double lluvia3h;

  /// km/h.
  final double velocidadViento;

  /// De 0 a 1.
  final double probabilidadLluvia;
  final int codigoClima;
  final String descripcion;

  /// Intensidad media en mm/h (D-10).
  double get lluviaPorHora => lluvia3h / 3;

  Map<String, dynamic> toMap() => {
    'fechaHora': fechaHora.millisecondsSinceEpoch,
    'temperatura': temperatura,
    'temperaturaMinima': temperaturaMinima,
    'temperaturaMaxima': temperaturaMaxima,
    'humedadRelativa': humedadRelativa,
    'lluvia3h': lluvia3h,
    'velocidadViento': velocidadViento,
    'probabilidadLluvia': probabilidadLluvia,
    'codigoClima': codigoClima,
    'descripcion': descripcion,
  };

  /// Para la caché local del pronóstico por horas (D-12).
  factory FranjaPronostico.fromMap(Map<String, dynamic> mapa) =>
      FranjaPronostico(
        fechaHora: DateTime.fromMillisecondsSinceEpoch(
          mapa['fechaHora'] as int,
          isUtc: true,
        ),
        temperatura: (mapa['temperatura'] as num).toDouble(),
        temperaturaMinima: (mapa['temperaturaMinima'] as num).toDouble(),
        temperaturaMaxima: (mapa['temperaturaMaxima'] as num).toDouble(),
        humedadRelativa: (mapa['humedadRelativa'] as num).toDouble(),
        lluvia3h: (mapa['lluvia3h'] as num? ?? 0).toDouble(),
        velocidadViento: (mapa['velocidadViento'] as num).toDouble(),
        probabilidadLluvia: (mapa['probabilidadLluvia'] as num? ?? 0)
            .toDouble(),
        codigoClima: mapa['codigoClima'] as int? ?? 800,
        descripcion: mapa['descripcion'] as String? ?? '',
      );
}
