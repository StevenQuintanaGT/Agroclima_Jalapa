/// Perfil del productor: `usuarios/{uid}` (Tabla 64, MODELO_DATOS §3).
class Usuario {
  const Usuario({
    required this.uid,
    required this.nombre,
    required this.correo,
    this.telefono = '',
    this.fechaRegistro,
    this.unidadTemperatura = 'C',
    this.unidadArea = 'manzana',
    this.temaOscuro = false,
    this.ahorroDatos = false,
    this.tokensFcm = const [],
  });

  final String uid;
  final String nombre;
  final String correo;

  /// Con código de país, p. ej. `+50245829385`; vacío si no lo dio.
  final String telefono;

  /// La pone el servidor al crear el documento.
  final DateTime? fechaRegistro;

  /// `C` o `F`.
  final String unidadTemperatura;

  /// `manzana` o `hectarea`.
  final String unidadArea;
  final bool temaOscuro;
  final bool ahorroDatos;
  final List<String> tokensFcm;

  /// Campos que escribe la app. `fechaRegistro` lo agrega el repositorio con
  /// la hora del servidor.
  Map<String, dynamic> toMap() => {
    'uid': uid,
    'nombre': nombre,
    'telefono': telefono,
    'correo': correo,
    'unidadTemperatura': unidadTemperatura,
    'unidadArea': unidadArea,
    'temaOscuro': temaOscuro,
    'ahorroDatos': ahorroDatos,
    'tokensFcm': tokensFcm,
  };

  /// [fecha] convierte el `Timestamp` de Firestore; el repositorio la aporta
  /// para que el modelo no dependa de Firebase.
  factory Usuario.fromMap(
    Map<String, dynamic> mapa, {
    DateTime? Function(Object? valor)? fecha,
  }) => Usuario(
    uid: mapa['uid'] as String,
    nombre: mapa['nombre'] as String? ?? '',
    correo: mapa['correo'] as String? ?? '',
    telefono: mapa['telefono'] as String? ?? '',
    fechaRegistro: fecha?.call(mapa['fechaRegistro']),
    unidadTemperatura: mapa['unidadTemperatura'] as String? ?? 'C',
    unidadArea: mapa['unidadArea'] as String? ?? 'manzana',
    temaOscuro: mapa['temaOscuro'] as bool? ?? false,
    ahorroDatos: mapa['ahorroDatos'] as bool? ?? false,
    tokensFcm: List<String>.from(mapa['tokensFcm'] as List? ?? const []),
  );
}
