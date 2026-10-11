import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Abre el menú de compartir del teléfono (WhatsApp, correo, Drive, "Guardar
/// en el teléfono") y el servicio de impresión de Android. Aparte para poder
/// probar las pantallas sin los menús del sistema.
class CompartirServicio {
  Future<void> compartirTexto(String texto) async {
    try {
      await SharePlus.instance.share(ShareParams(text: texto));
    } catch (error) {
      debugPrint('No se pudo compartir: $error');
    }
  }

  /// Comparte un archivo armado en el teléfono (reportes, D-51).
  Future<void> compartirArchivo(
    Uint8List bytes, {
    required String nombre,
    required String tipoMime,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: tipoMime, name: nombre)],
          fileNameOverrides: [nombre],
        ),
      );
    } catch (error) {
      debugPrint('No se pudo compartir el archivo: $error');
    }
  }

  /// Abre la impresión de Android con el PDF (impresora de la red o "Guardar
  /// como PDF"). `false` si el teléfono no puede imprimir.
  Future<bool> imprimirPdf(Uint8List pdf, {required String nombre}) async {
    try {
      final info = await Printing.info();
      if (!info.canPrint) return false;
      await Printing.layoutPdf(onLayout: (_) async => pdf, name: nombre);
      return true;
    } catch (error) {
      debugPrint('No se pudo imprimir: $error');
      return false;
    }
  }
}
