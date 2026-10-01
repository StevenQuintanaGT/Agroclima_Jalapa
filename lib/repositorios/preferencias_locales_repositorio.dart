/// Marcas pequeñas guardadas solo en el teléfono (no son datos del productor).
/// Lectura síncrona: el enrutador las consulta en su guarda.
/// Implementación: `SharedPreferencesLocalesRepositorio`.
abstract class PreferenciasLocalesRepositorio {
  /// ¿Ya vio las 3 pantallas de bienvenida? (plans/01, flujo 1).
  bool get bienvenidaVista;
  Future<void> marcarBienvenidaVista();

  /// ¿Ya se le explicaron los permisos de ubicación y avisos (pantallas 08–09)?
  /// "Ahora no" también cuenta: no se vuelven a ofrecer al entrar (RNF-05).
  bool get permisosOfrecidos;
  Future<void> marcarPermisosOfrecidos();
}
