import '../config/constantes.dart';
import '../modelos/enums.dart';
import '../modelos/parcela.dart';
import '../repositorios/auth_repositorio.dart';
import '../repositorios/parcelas_repositorio.dart';
import 'celda_clima.dart';
import 'validacion_geografica.dart';

/// Error de negocio al registrar una parcela.
class ErrorParcela implements Exception {
  const ErrorParcela(this.motivo);

  final MotivoErrorParcela motivo;

  @override
  String toString() => 'ErrorParcela($motivo)';
}

enum MotivoErrorParcela { fueraDeJalapa, nombreRepetido, sinSesion }

/// Casos de uso de parcelas (MOD-02).
class ParcelasServicio {
  ParcelasServicio({
    required this._repositorio,
    required this._auth,
    required this._validacion,
  });

  final ParcelasRepositorio _repositorio;
  final AuthRepositorio _auth;
  final ValidacionGeografica _validacion;

  ValidacionGeografica get validacion => _validacion;

  /// Nombres ya usados por el productor (VA-02). Vacío si no hay sesión.
  Future<List<String>> nombresUsados() async {
    final uid = _auth.uidActual;
    if (uid == null) return const [];
    return _repositorio.nombres(uid);
  }

  /// Parcelas del productor con sesión, en vivo. Vacío si no hay sesión.
  Stream<List<Parcela>> misParcelas() {
    final uid = _auth.uidActual;
    if (uid == null) return Stream.value(const []);
    return _repositorio.listar(uid);
  }

  /// Una parcela en vivo; `null` si se borró.
  Stream<Parcela?> observar(String parcelaId) =>
      _repositorio.observar(parcelaId);

  /// VA-02: mismo nombre sin importar mayúsculas, tildes ni espacios.
  static bool nombreRepetido(String nombre, Iterable<String> usados) {
    final buscado = _normalizar(nombre);
    return usados.any((usado) => _normalizar(usado) == buscado);
  }

  static bool nombreValido(String nombre) {
    final limpio = nombre.trim();
    return limpio.isNotEmpty &&
        limpio.length <= Constantes.largoMaximoNombreParcela;
  }

  /// Registra la parcela (HU-03 a HU-05). El municipio sale del punto, no de
  /// lo que se eligió en el paso 1 (RN-02). Lanza [ErrorParcela].
  Future<ParcelaGuardada> registrar({
    required String nombre,
    required double latitud,
    required double longitud,
    Cultivo? cultivo,
    Etapa? etapa,
    int? altitud,
    double? area,
    String unidadArea = 'manzana',
  }) async {
    final uid = _auth.uidActual;
    if (uid == null) throw const ErrorParcela(MotivoErrorParcela.sinSesion);
    final municipio = _validacion.municipioDe(latitud, longitud);
    if (municipio == null) {
      throw const ErrorParcela(MotivoErrorParcela.fueraDeJalapa);
    }
    if (nombreRepetido(nombre, await _repositorio.nombres(uid))) {
      throw const ErrorParcela(MotivoErrorParcela.nombreRepetido);
    }
    return _repositorio.crear(
      Parcela(
        usuarioId: uid,
        nombre: nombre.trim(),
        municipio: municipio,
        cultivo: cultivo,
        etapa: cultivo == null ? null : etapa,
        latitud: latitud,
        longitud: longitud,
        altitud: altitud,
        area: area,
        unidadArea: unidadArea,
        celdaClima: CeldaClima.calcular(latitud, longitud),
      ),
    );
  }

  /// Guarda los cambios de [original] (HU-06). Si cambia el punto se
  /// recalculan municipio y `celdaClima`; si cambian cultivo o etapa, el
  /// próximo ciclo evalúa con los umbrales nuevos. Devuelve `true` si quedó
  /// pendiente de subir. Lanza [ErrorParcela].
  Future<bool> actualizar({
    required Parcela original,
    required String nombre,
    required double latitud,
    required double longitud,
    Cultivo? cultivo,
    Etapa? etapa,
    int? altitud,
    double? area,
    String unidadArea = 'manzana',
  }) async {
    final uid = _auth.uidActual;
    if (uid == null || uid != original.usuarioId) {
      throw const ErrorParcela(MotivoErrorParcela.sinSesion);
    }
    final municipio = _validacion.municipioDe(latitud, longitud);
    if (municipio == null) {
      throw const ErrorParcela(MotivoErrorParcela.fueraDeJalapa);
    }
    final otros = [
      for (final usado in await _repositorio.nombres(uid))
        if (usado != original.nombre) usado,
    ];
    if (nombreRepetido(nombre, otros)) {
      throw const ErrorParcela(MotivoErrorParcela.nombreRepetido);
    }
    return _repositorio.actualizar(
      Parcela(
        parcelaId: original.parcelaId,
        usuarioId: uid,
        nombre: nombre.trim(),
        municipio: municipio,
        cultivo: cultivo,
        etapa: cultivo == null ? null : etapa,
        latitud: latitud,
        longitud: longitud,
        altitud: altitud,
        area: area,
        unidadArea: unidadArea,
        celdaClima: CeldaClima.calcular(latitud, longitud),
        activa: original.activa,
        fechaRegistro: original.fechaRegistro,
      ),
    );
  }

  /// Borra la parcela (HU-06). Devuelve `true` si quedó pendiente de subir.
  Future<bool> eliminar(String parcelaId) => _repositorio.eliminar(parcelaId);

  static String _normalizar(String texto) => texto
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp('[áà]'), 'a')
      .replaceAll(RegExp('[éè]'), 'e')
      .replaceAll(RegExp('[íì]'), 'i')
      .replaceAll(RegExp('[óò]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u');
}
