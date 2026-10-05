import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// Abre el menú de compartir del teléfono (WhatsApp, mensajes…) con un texto.
/// Aparte para poder probar las pantallas sin el menú del sistema.
class CompartirServicio {
  Future<void> compartirTexto(String texto) async {
    try {
      await SharePlus.instance.share(ShareParams(text: texto));
    } catch (error) {
      debugPrint('No se pudo compartir: $error');
    }
  }
}
