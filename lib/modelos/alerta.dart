import 'enums.dart';

/// Alerta de riesgo climático: `alertas/{alertaId}` (Tabla 69). La crea el
/// ciclo en la nube; la app solo cambia `leida` y `atendida`.
class Alerta {
  const Alerta({
    required this.alertaId,
    required this.usuarioId,
    required this.parcelaId,
    required this.tipoRiesgo,
    required this.nivel,
    required this.valorEsperado,
    required this.valorUmbral,
    required this.mensaje,
    required this.fechaEvento,
    this.medidaSugerida = '',
    this.fechaGeneracion,
    this.leida = false,
    this.atendida = false,
    this.parcelaNombre = '',
    this.cultivo,
    this.diasConsecutivos,
    this.notificada = false,
  });

  final String alertaId;
  final String usuarioId;
  final String parcelaId;
  final TipoRiesgo tipoRiesgo;
  final NivelSeveridad nivel;

  /// Valor pronosticado (°C, mm/h, km/h, %, o días para la sequía).
  final double valorEsperado;

  /// Lo que aguanta el cultivo según el umbral (D-14).
  final double valorUmbral;
  final String mensaje;
  final String medidaSugerida;

  /// 00:00 en Guatemala del día del evento (instante UTC).
  final DateTime fechaEvento;

  /// `null` mientras el servidor no pone la hora (copia local recién creada).
  final DateTime? fechaGeneracion;
  final bool leida;
  final bool atendida;
  final String parcelaNombre;
  final Cultivo? cultivo;
  final int? diasConsecutivos;
  final bool notificada;

  /// Helada: frío con umbral de 0 °C o menos (Tabla 31).
  bool get esHelada =>
      tipoRiesgo == TipoRiesgo.temperaturaBaja && valorUmbral <= 0;

  /// `null` si el documento no se entiende (tipo o nivel desconocidos):
  /// mejor no mostrarla que mostrarla mal.
  static Alerta? fromMap(
    String id,
    Map<String, dynamic> mapa, {
    required DateTime fechaEvento,
    DateTime? fechaGeneracion,
  }) {
    final tipo = TipoRiesgo.desdeValor(mapa['tipoRiesgo'] as String?);
    final nivel = NivelSeveridad.desdeValor(mapa['nivel'] as String?);
    final esperado = mapa['valorEsperado'];
    final umbral = mapa['valorUmbral'];
    if (tipo == null || nivel == null || esperado is! num || umbral is! num) {
      return null;
    }
    return Alerta(
      alertaId: id,
      usuarioId: mapa['usuarioId'] as String? ?? '',
      parcelaId: mapa['parcelaId'] as String? ?? '',
      tipoRiesgo: tipo,
      nivel: nivel,
      valorEsperado: esperado.toDouble(),
      valorUmbral: umbral.toDouble(),
      mensaje: mapa['mensaje'] as String? ?? '',
      medidaSugerida: mapa['medidaSugerida'] as String? ?? '',
      fechaEvento: fechaEvento,
      fechaGeneracion: fechaGeneracion,
      leida: mapa['leida'] as bool? ?? false,
      atendida: mapa['atendida'] as bool? ?? false,
      parcelaNombre: mapa['parcelaNombre'] as String? ?? '',
      cultivo: Cultivo.desdeValor(mapa['cultivo'] as String?),
      diasConsecutivos: (mapa['diasConsecutivos'] as num?)?.toInt(),
      notificada: mapa['notificada'] as bool? ?? false,
    );
  }

  Alerta copyWith({bool? leida, bool? atendida}) => Alerta(
    alertaId: alertaId,
    usuarioId: usuarioId,
    parcelaId: parcelaId,
    tipoRiesgo: tipoRiesgo,
    nivel: nivel,
    valorEsperado: valorEsperado,
    valorUmbral: valorUmbral,
    mensaje: mensaje,
    medidaSugerida: medidaSugerida,
    fechaEvento: fechaEvento,
    fechaGeneracion: fechaGeneracion,
    leida: leida ?? this.leida,
    atendida: atendida ?? this.atendida,
    parcelaNombre: parcelaNombre,
    cultivo: cultivo,
    diasConsecutivos: diasConsecutivos,
    notificada: notificada,
  );
}
