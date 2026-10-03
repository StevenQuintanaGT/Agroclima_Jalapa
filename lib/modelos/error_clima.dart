/// Por qué no se pudo traer el clima. La pantalla lo convierte en una causa
/// probable en lenguaje llano (pantalla 34); nunca se muestra el código.
enum MotivoErrorClima {
  sinConexion,
  tiempoAgotado,
  claveInvalida,
  limiteAlcanzado,
  servicioCaido,
  respuestaInvalida,
}

class ErrorClima implements Exception {
  const ErrorClima(this.motivo);

  final MotivoErrorClima motivo;

  @override
  String toString() => 'ErrorClima($motivo)';
}
