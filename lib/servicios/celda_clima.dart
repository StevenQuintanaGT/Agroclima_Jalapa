import '../config/constantes.dart';

/// Celda climática (DECISIONES D-07): las coordenadas se redondean a
/// 0.05° (~5.5 km) para que las parcelas cercanas compartan una sola consulta
/// a OpenWeather (RN-06, cuota del plan gratuito).
class CeldaClima {
  CeldaClima._();

  /// Id de la celda, p. ej. `14.65_-89.95`. Debe dar exactamente lo mismo
  /// que `functions/src/` (mismo redondeo y 2 decimales).
  static String calcular(double lat, double lon) =>
      '${_redondear(lat)}_${_redondear(lon)}';

  /// Centro de la celda: el punto que se consulta al proveedor.
  static ({double lat, double lon}) centro(String idCelda) {
    final partes = idCelda.split('_');
    return (lat: double.parse(partes[0]), lon: double.parse(partes[1]));
  }

  static String _redondear(double valor) {
    const tamano = Constantes.tamanoCeldaGrados;
    final redondeado = (valor / tamano).round() * tamano;
    // toStringAsFixed evita restos como 14.650000000000002.
    final texto = redondeado.toStringAsFixed(2);
    return texto == '-0.00' ? '0.00' : texto;
  }
}
