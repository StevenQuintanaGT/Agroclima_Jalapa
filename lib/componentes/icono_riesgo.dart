import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../modelos/alerta.dart';
import '../modelos/enums.dart';

/// Ícono de cada tipo de riesgo (pantallas 21, 22, 23 y 24).
class IconoRiesgo {
  IconoRiesgo._();

  static IconData de(Alerta alerta) => deTipo(alerta.tipoRiesgo);

  static IconData deTipo(TipoRiesgo tipo) => switch (tipo) {
    TipoRiesgo.temperaturaBaja => Symbols.ac_unit,
    TipoRiesgo.lluviaIntensa => Symbols.rainy,
    TipoRiesgo.vientoFuerte => Symbols.air,
    TipoRiesgo.sequia => Symbols.local_fire_department,
    TipoRiesgo.temperaturaAlta => Symbols.thermostat,
    TipoRiesgo.humedadAlta => Symbols.humidity_percentage,
  };
}
