import 'package:flutter/painting.dart';

/// Escala tipográfica (Tabla 73 y handoff de diseño). Roboto, tamaños en sp:
/// respetan el tamaño de letra del teléfono (no se fija `textScaler`).
/// Mínimo de cuerpo: 16 sp; 13–15 sp solo como etiqueta junto a un dato mayor.
class Tipografia {
  Tipografia._();

  static const String familia = 'Roboto';

  /// Temperatura actual en el panel.
  static const TextStyle datoDestacado = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w900,
    height: 1,
    letterSpacing: -1.28,
  );

  /// Valor esperado en el detalle de alerta.
  static const TextStyle datoGrande = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    height: 1,
  );

  /// Títulos de alerta y onboarding.
  static const TextStyle titular = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Títulos de pantalla.
  static const TextStyle titulo = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  /// Encabezados de sección.
  static const TextStyle subtitulo = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Explicaciones de alerta o permiso, filas de lista, valor de campo.
  static const TextStyle cuerpoGrande = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  /// Texto general.
  static const TextStyle cuerpo = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Metadatos dentro de tarjeta y etiquetas de campo.
  static const TextStyle cuerpoChico = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  /// Etiquetas bajo íconos.
  static const TextStyle etiqueta = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  /// Palabra del semáforo en chips y barra inferior.
  static const TextStyle etiquetaChica = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// Texto de botón principal.
  static const TextStyle boton = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}
