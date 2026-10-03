import 'enums.dart';

/// Parcela del productor: `parcelas/{parcelaId}` (Tabla 66, MODELO_DATOS §3).
class Parcela {
  const Parcela({
    this.parcelaId = '',
    required this.usuarioId,
    required this.nombre,
    required this.municipio,
    this.cultivo,
    this.etapa,
    required this.latitud,
    required this.longitud,
    this.altitud,
    this.area,
    this.unidadArea = 'manzana',
    required this.celdaClima,
    this.activa = true,
    this.fechaRegistro,
  });

  /// Vacío hasta que Firestore asigna el id al crear.
  final String parcelaId;
  final String usuarioId;
  final String nombre;
  final Municipio municipio;

  /// `null` = todavía no ha sembrado (solo alertas generales, RN-05).
  final Cultivo? cultivo;
  final Etapa? etapa;
  final double latitud;
  final double longitud;

  /// Metros sobre el nivel del mar; opcional.
  final int? altitud;

  /// Tamaño en la unidad que escribió el productor; opcional, > 0 (VA-03).
  final double? area;

  /// `manzana` o `hectarea`.
  final String unidadArea;
  final String celdaClima;
  final bool activa;
  final DateTime? fechaRegistro;

  /// Campos que escribe la app, sin la ubicación ni las fechas: el
  /// repositorio agrega el `GeoPoint` y las marcas de tiempo del servidor
  /// para que el modelo no dependa de Firebase.
  Map<String, dynamic> toMap() => {
    'usuarioId': usuarioId,
    'nombre': nombre,
    'municipio': municipio.valor,
    'cultivo': cultivo?.valor ?? '',
    'etapa': etapa?.valor ?? '',
    'altitud': altitud,
    'area': area,
    'unidadArea': unidadArea,
    'celdaClima': celdaClima,
    'activa': activa,
  };

  factory Parcela.fromMap(
    String id,
    Map<String, dynamic> mapa, {
    required double latitud,
    required double longitud,
    DateTime? fechaRegistro,
  }) => Parcela(
    parcelaId: id,
    usuarioId: mapa['usuarioId'] as String,
    nombre: mapa['nombre'] as String? ?? '',
    municipio:
        Municipio.desdeValor(mapa['municipio'] as String?) ?? Municipio.jalapa,
    cultivo: Cultivo.desdeValor(mapa['cultivo'] as String?),
    etapa: Etapa.desdeValor(mapa['etapa'] as String?),
    latitud: latitud,
    longitud: longitud,
    altitud: (mapa['altitud'] as num?)?.toInt(),
    area: (mapa['area'] as num?)?.toDouble(),
    unidadArea: mapa['unidadArea'] as String? ?? 'manzana',
    celdaClima: mapa['celdaClima'] as String? ?? '',
    activa: mapa['activa'] as bool? ?? true,
    fechaRegistro: fechaRegistro,
  );
}
