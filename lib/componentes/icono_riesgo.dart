import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../modelos/alerta.dart';
import '../modelos/enums.dart';

/// Ícono de cada tipo de riesgo (pantallas 21, 22 y 24).
class IconoRiesgo {
  IconoRiesgo._();

  static IconData de(Alerta alerta) => switch (alerta.tipoRiesgo) {
    TipoRiesgo.temperaturaBaja => Symbols.ac_unit,
    TipoRiesgo.lluviaIntensa => Symbols.rainy,
    TipoRiesgo.vientoFuerte => Symbols.air,
    TipoRiesgo.sequia => Symbols.wb_sunny,
    TipoRiesgo.temperaturaAlta => Symbols.thermostat,
    TipoRiesgo.humedadAlta => Symbols.humidity_percentage,
  };
}
