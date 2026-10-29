import 'package:flutter/foundation.dart';

import '../../modelos/respuestas_encuesta.dart';
import '../../servicios/encuesta_servicio.dart';

/// Estado de "Su opinión" (D-58): carga lo que ya respondió para poder
/// cambiarlo, lleva las elecciones y envía.
class EncuestaVm extends ChangeNotifier {
  EncuestaVm(this._servicio) {
    _cargar();
  }

  final EncuestaServicio _servicio;
  RespuestasEncuesta _respuestas = const RespuestasEncuesta();
  bool _cargando = true;
  bool _yaRespondio = false;
  DateTime? _fechaRespuesta;
  bool _enviando = false;
  bool _descartado = false;

  RespuestasEncuesta get respuestas => _respuestas;
  bool get cargando => _cargando;

  /// Ya había enviado antes: la pantalla lo dice y deja cambiarlo.
  bool get yaRespondio => _yaRespondio;
  DateTime? get fechaRespuesta => _fechaRespuesta;
  bool get enviando => _enviando;

  /// "Enviar" se habilita con las preguntas obligatorias y el permiso.
  bool get puedeEnviar => !_cargando && !_enviando && _respuestas.completa;

  Future<void> _cargar() async {
    try {
      final anterior = await _servicio.miEncuesta();
      if (anterior != null) {
        _respuestas = anterior.respuestas;
        _yaRespondio = true;
        _fechaRespuesta = anterior.fechaRespuesta;
      }
    } catch (error) {
      // Sin señal y sin copia: se empieza en blanco.
      debugPrint('No se leyó la encuesta anterior: $error');
    } finally {
      _cargando = false;
      _avisar();
    }
  }

  void elegir(String pregunta, String valor) {
    _respuestas = _respuestas.elegir(pregunta, valor);
    _avisar();
  }

  void cambiarDetalleAviso(String texto) =>
      _respuestas = _respuestas.copyWith(detalleAviso: texto);

  void cambiarDetalleAccion(String texto) =>
      _respuestas = _respuestas.copyWith(detalleAccion: texto);

  void cambiarDetalleDanio(String texto) =>
      _respuestas = _respuestas.copyWith(detalleDanio: texto);

  void cambiarSugerencia(String texto) =>
      _respuestas = _respuestas.copyWith(p8: texto);

  void cambiarConsentimiento(bool valor) {
    _respuestas = _respuestas.copyWith(consentimiento: valor);
    _avisar();
  }

  /// `true` si quedó guardada (sin señal queda en el teléfono y se sube sola).
  Future<bool> enviar() async {
    if (!puedeEnviar) return false;
    _enviando = true;
    _avisar();
    try {
      await _servicio.enviar(_respuestas);
      return true;
    } catch (error) {
      debugPrint('No se envió la encuesta: $error');
      return false;
    } finally {
      _enviando = false;
      _avisar();
    }
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
