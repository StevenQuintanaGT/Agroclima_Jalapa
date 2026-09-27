import 'package:flutter/material.dart';

import '../../modelos/enums.dart';
import 'colores.dart';

/// Colores de un nivel del semáforo.
@immutable
class TonoSemaforo {
  const TonoSemaforo({
    required this.borde,
    required this.fondo,
    required this.texto,
    required this.icono,
  });

  final Color borde;
  final Color fondo;
  final Color texto;
  final Color icono;

  static TonoSemaforo lerp(TonoSemaforo a, TonoSemaforo b, double t) =>
      TonoSemaforo(
        borde: Color.lerp(a.borde, b.borde, t)!,
        fondo: Color.lerp(a.fondo, b.fondo, t)!,
        texto: Color.lerp(a.texto, b.texto, t)!,
        icono: Color.lerp(a.icono, b.icono, t)!,
      );
}

/// Semáforo de riesgo como extensión del tema, para que claro y oscuro usen
/// los tonos que cumplen contraste AA (Tabla 72, DECISIONES D-04).
@immutable
class ColoresSemaforo extends ThemeExtension<ColoresSemaforo> {
  const ColoresSemaforo({
    required this.normal,
    required this.precaucion,
    required this.peligro,
  });

  final TonoSemaforo normal;
  final TonoSemaforo precaucion;
  final TonoSemaforo peligro;

  static const claro = ColoresSemaforo(
    normal: TonoSemaforo(
      borde: Colores.normalBorde,
      fondo: Colores.normalFondo,
      texto: Colores.normalTexto,
      icono: Colores.normalIcono,
    ),
    precaucion: TonoSemaforo(
      borde: Colores.precaucionBorde,
      fondo: Colores.precaucionFondo,
      texto: Colores.precaucionTexto,
      icono: Colores.precaucionIcono,
    ),
    peligro: TonoSemaforo(
      borde: Colores.peligroBorde,
      fondo: Colores.peligroFondo,
      texto: Colores.peligroTexto,
      icono: Colores.peligroIcono,
    ),
  );

  // En oscuro el ámbar #B26A00 no cumple AA: se usa #F6C453.
  static const oscuro = ColoresSemaforo(
    normal: TonoSemaforo(
      borde: Colores.primarioTemaOscuro,
      fondo: Colores.normalFondoOscuro,
      texto: Colores.normalTextoOscuro,
      icono: Colores.normalTextoOscuro,
    ),
    precaucion: TonoSemaforo(
      borde: Colores.precaucionTextoOscuro,
      fondo: Colores.precaucionFondoOscuro,
      texto: Colores.precaucionTextoOscuro,
      icono: Colores.precaucionTextoOscuro,
    ),
    peligro: TonoSemaforo(
      borde: Colores.peligroBordeOscuro,
      fondo: Colores.peligroFondoOscuro,
      texto: Colores.peligroTextoOscuro,
      icono: Colores.peligroTextoOscuro,
    ),
  );

  TonoSemaforo de(NivelSeveridad nivel) => switch (nivel) {
    NivelSeveridad.informativa => normal,
    NivelSeveridad.preventiva => precaucion,
    NivelSeveridad.critica => peligro,
  };

  static ColoresSemaforo of(BuildContext context) =>
      Theme.of(context).extension<ColoresSemaforo>() ?? claro;

  @override
  ColoresSemaforo copyWith({
    TonoSemaforo? normal,
    TonoSemaforo? precaucion,
    TonoSemaforo? peligro,
  }) => ColoresSemaforo(
    normal: normal ?? this.normal,
    precaucion: precaucion ?? this.precaucion,
    peligro: peligro ?? this.peligro,
  );

  @override
  ColoresSemaforo lerp(ColoresSemaforo? other, double t) {
    if (other == null) return this;
    return ColoresSemaforo(
      normal: TonoSemaforo.lerp(normal, other.normal, t),
      precaucion: TonoSemaforo.lerp(precaucion, other.precaucion, t),
      peligro: TonoSemaforo.lerp(peligro, other.peligro, t),
    );
  }
}
