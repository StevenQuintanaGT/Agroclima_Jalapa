import 'respuestas_encuesta.dart';

/// Documento `encuestas/{uid}` (D-58): las respuestas del productor y, para
/// agrupar los resultados, el municipio y el cultivo de su primera parcela y
/// la versión de la app con que respondió.
class Encuesta {
  const Encuesta({
    required this.uid,
    required this.respuestas,
    this.municipio,
    this.cultivo,
    required this.versionApp,
    this.fechaRespuesta,
  });

  final String uid;
  final RespuestasEncuesta respuestas;

  /// Valor guardado del municipio (`monjas`…), si tiene parcela.
  final String? municipio;

  /// Valor guardado del cultivo (`maiz`…), si su parcela tiene cultivo.
  final String? cultivo;
  final String versionApp;

  /// Hora del servidor de la última vez que envió.
  final DateTime? fechaRespuesta;

  /// Sin `fechaRespuesta`: la pone el repositorio con la hora del servidor.
  Map<String, dynamic> toMap() => {
    'uid': uid,
    ...respuestas.toMap(),
    'municipio': ?municipio,
    'cultivo': ?cultivo,
    'versionApp': versionApp,
  };

  factory Encuesta.fromMap(
    Map<String, dynamic> mapa, {
    required DateTime? Function(Object?) fecha,
  }) => Encuesta(
    uid: mapa['uid'] as String,
    respuestas: RespuestasEncuesta.fromMap(mapa),
    municipio: mapa['municipio'] as String?,
    cultivo: mapa['cultivo'] as String?,
    versionApp: mapa['versionApp'] as String? ?? '',
    fechaRespuesta: fecha(mapa['fechaRespuesta']),
  );
}
