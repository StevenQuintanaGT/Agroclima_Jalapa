import 'package:agroclima_jalapa/repositorios/preferencias_locales_repositorio.dart';

/// Preferencias en memoria para las pruebas.
class PreferenciasFalsas implements PreferenciasLocalesRepositorio {
  PreferenciasFalsas({
    this.bienvenidaVista = false,
    this.permisosOfrecidos = false,
  });

  @override
  bool bienvenidaVista;

  @override
  bool permisosOfrecidos;

  @override
  Future<void> marcarBienvenidaVista() async => bienvenidaVista = true;

  @override
  Future<void> marcarPermisosOfrecidos() async => permisosOfrecidos = true;
}
