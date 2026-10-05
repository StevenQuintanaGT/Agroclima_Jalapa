import 'enums.dart';

/// Preferencia de avisos por tipo de riesgo:
/// `usuarios/{uid}/preferencias/{tipoRiesgo}` (Tabla 65).
class PreferenciaAlerta {
  const PreferenciaAlerta({
    required this.tipoRiesgo,
    this.activa = true,
    this.nivelMinimo = NivelSeveridad.preventiva,
    this.silencioDesde = '22:00',
    this.silencioHasta = '05:00',
  });

  /// Valores por defecto que se crean al registrar la cuenta.
  factory PreferenciaAlerta.porDefecto(TipoRiesgo tipo) =>
      PreferenciaAlerta(tipoRiesgo: tipo);

  final TipoRiesgo tipoRiesgo;
  final bool activa;
  final NivelSeveridad nivelMinimo;

  /// Hora local `HH:mm` sin avisos (salvo PELIGRO). Vacías = sin silencio
  /// (el ciclo las lee igual, `functions/src/notificaciones.js`).
  final String silencioDesde;
  final String silencioHasta;

  static const String silencioDesdePorDefecto = '22:00';
  static const String silencioHastaPorDefecto = '05:00';

  bool get silencioActivo =>
      silencioDesde.isNotEmpty &&
      silencioHasta.isNotEmpty &&
      silencioDesde != silencioHasta;

  PreferenciaAlerta copyWith({
    bool? activa,
    NivelSeveridad? nivelMinimo,
    String? silencioDesde,
    String? silencioHasta,
  }) => PreferenciaAlerta(
    tipoRiesgo: tipoRiesgo,
    activa: activa ?? this.activa,
    nivelMinimo: nivelMinimo ?? this.nivelMinimo,
    silencioDesde: silencioDesde ?? this.silencioDesde,
    silencioHasta: silencioHasta ?? this.silencioHasta,
  );

  Map<String, dynamic> toMap() => {
    'tipoRiesgo': tipoRiesgo.valor,
    'activa': activa,
    'nivelMinimo': nivelMinimo.valor,
    'silencioDesde': silencioDesde,
    'silencioHasta': silencioHasta,
  };

  factory PreferenciaAlerta.fromMap(Map<String, dynamic> mapa) =>
      PreferenciaAlerta(
        tipoRiesgo: TipoRiesgo.desdeValor(mapa['tipoRiesgo'] as String?)!,
        activa: mapa['activa'] as bool? ?? true,
        nivelMinimo:
            NivelSeveridad.desdeValor(mapa['nivelMinimo'] as String?) ??
            NivelSeveridad.preventiva,
        silencioDesde: mapa['silencioDesde'] as String? ?? '22:00',
        silencioHasta: mapa['silencioHasta'] as String? ?? '05:00',
      );
}
