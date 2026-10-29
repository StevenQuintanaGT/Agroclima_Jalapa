import 'dart:async';

import '../config/constantes.dart';
import '../modelos/encuesta.dart';
import '../modelos/parcela.dart';
import '../modelos/respuestas_encuesta.dart';
import '../repositorios/auth_repositorio.dart';
import '../repositorios/encuestas_repositorio.dart';
import 'parcelas_servicio.dart';

/// Encuesta de satisfacción ("Su opinión", D-58): lee lo que ya respondió y
/// guarda las respuestas con el municipio y cultivo de su primera parcela y
/// la versión de la app.
class EncuestaServicio {
  EncuestaServicio({
    required this._auth,
    required this._repositorio,
    required this._parcelas,
  });

  final AuthRepositorio _auth;
  final EncuestasRepositorio _repositorio;
  final ParcelasServicio _parcelas;

  /// Sin señal ni copia local, las parcelas pueden no llegar: se envía igual.
  static const Duration esperaParcelas = Duration(seconds: 5);

  /// Lo que ya respondió, o `null` si no ha respondido (o no hay sesión).
  Future<Encuesta?> miEncuesta() async {
    final uid = _auth.uidActual;
    if (uid == null) return null;
    return _repositorio.obtener(uid);
  }

  /// Guarda las respuestas (reemplaza las anteriores). Lanza [StateError]
  /// sin sesión o si faltan respuestas obligatorias.
  Future<void> enviar(RespuestasEncuesta respuestas) async {
    final uid = _auth.uidActual;
    if (uid == null) throw StateError('Sin sesión');
    if (!respuestas.completa) throw StateError('Faltan respuestas');
    final primera = await _primeraParcela();
    await _repositorio.guardar(
      Encuesta(
        uid: uid,
        respuestas: respuestas.limpias(),
        municipio: primera?.municipio.valor,
        cultivo: primera?.cultivo?.valor,
        versionApp: Constantes.versionApp,
      ),
    );
  }

  /// La parcela registrada primero (si no hay fecha, la primera de la lista).
  Future<Parcela?> _primeraParcela() async {
    try {
      final lista = await _parcelas.misParcelas().first.timeout(esperaParcelas);
      if (lista.isEmpty) return null;
      final ordenadas = [...lista]
        ..sort((a, b) {
          final fa = a.fechaRegistro, fb = b.fechaRegistro;
          if (fa == null && fb == null) return 0;
          if (fa == null || fb == null) return fa == null ? 1 : -1;
          return fa.compareTo(fb);
        });
      return ordenadas.first;
    } catch (_) {
      return null;
    }
  }
}
