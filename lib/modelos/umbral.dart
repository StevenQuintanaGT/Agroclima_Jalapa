import 'enums.dart';

/// Umbral agrometeorológico: `umbrales/{umbralId}` (Tabla 70). Solo lectura
/// para la app (RNF-19); sirve para mostrar "lo que aguanta el cultivo".
class Umbral {
  const Umbral({
    required this.umbralId,
    required this.tipoRiesgo,
    required this.variable,
    required this.operador,
    required this.valor,
    required this.nivel,
    this.cultivo,
    this.etapa,
    this.duracionDias = 1,
    this.fuente = '',
    this.vigente = true,
  });

  final String umbralId;
  final TipoRiesgo tipoRiesgo;
  final String variable;

  /// `null` = general (aplica a todos los cultivos).
  final Cultivo? cultivo;

  /// `null` = todas las etapas.
  final Etapa? etapa;

  /// `mayor`, `mayorIgual`, `menor` o `menorIgual`.
  final String operador;
  final double valor;
  final int duracionDias;
  final NivelSeveridad nivel;
  final String fuente;
  final bool vigente;

  /// UMBRALES.md §3: general, o de su cultivo en cualquier etapa o en la suya.
  bool aplicaA(Cultivo? cultivoParcela, Etapa? etapaParcela) =>
      vigente &&
      (cultivo == null ||
          (cultivo == cultivoParcela &&
              (etapa == null || etapa == etapaParcela)));

  /// `null` si el documento no se entiende (se ignora, no rompe la pantalla).
  static Umbral? fromMap(String id, Map<String, dynamic> mapa) {
    final tipo = TipoRiesgo.desdeValor(mapa['tipoRiesgo'] as String?);
    final nivel = NivelSeveridad.desdeValor(mapa['nivel'] as String?);
    final valor = mapa['valor'];
    if (tipo == null || nivel == null || valor is! num) return null;
    return Umbral(
      umbralId: id,
      tipoRiesgo: tipo,
      variable: mapa['variable'] as String? ?? '',
      cultivo: Cultivo.desdeValor(mapa['cultivo'] as String?),
      etapa: Etapa.desdeValor(mapa['etapa'] as String?),
      operador: mapa['operador'] as String? ?? 'mayor',
      valor: valor.toDouble(),
      duracionDias: (mapa['duracionDias'] as num?)?.toInt() ?? 1,
      nivel: nivel,
      fuente: mapa['fuente'] as String? ?? '',
      vigente: mapa['vigente'] as bool? ?? true,
    );
  }
}
