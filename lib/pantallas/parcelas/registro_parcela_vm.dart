import 'package:flutter/foundation.dart';

import '../../config/textos.dart';
import '../../modelos/enums.dart';
import '../../modelos/parcela.dart';
import '../../servicios/busqueda_lugares_servicio.dart';
import '../../servicios/parcelas_servicio.dart';
import '../../servicios/ubicacion_servicio.dart';

/// Resultado de guardar, para que la pantalla sepa qué decir.
enum ResultadoGuardado { guardada, guardadaSinSenal, error }

/// Estado del registro de parcela en 4 pasos (pantallas 10–13; HU-03, HU-04
/// y HU-05). Una decisión por paso (RNF-12).
///
/// Con [original] edita esa parcela (HU-06): arranca en la revisión (o en
/// [pasoInicial]) con los datos cargados, y cada "Cambiar" vuelve a ella.
class RegistroParcelaVm extends ChangeNotifier {
  RegistroParcelaVm({
    required this._parcelas,
    required this._ubicacion,
    required this._busqueda,
    this._original,
    int? pasoInicial,
  }) {
    final original = _original;
    if (original == null) {
      final centro = _parcelas.validacion.centro();
      _latitud = centro.lat;
      _longitud = centro.lon;
    } else {
      _cargar(original);
      _paso = (pasoInicial ?? totalPasos).clamp(1, totalPasos);
      _volverARevision = _paso < totalPasos;
    }
    _cargarNombres();
  }

  static const int totalPasos = 4;

  final ParcelasServicio _parcelas;
  final UbicacionServicio _ubicacion;
  final BusquedaLugaresServicio _busqueda;
  final Parcela? _original;

  int _paso = 1;
  bool _volverARevision = false;
  bool _intentoAvanzar = false;
  bool _descartado = false;

  // Paso 1
  String _nombre = '';
  Municipio? _municipio;
  List<String> _nombresUsados = const [];

  // Paso 2
  Cultivo? _cultivo;
  Etapa? _etapa;
  bool _sinSembrar = false;

  // Paso 3
  late double _latitud;
  late double _longitud;
  bool _puntoPuesto = false;
  bool _fueraDeJalapa = false;
  String? _avisoPunto;
  String _altitudTexto = '';
  bool _altitudDelGps = false;
  String _areaTexto = '';
  String _unidadArea = 'manzana';
  bool _ubicando = false;
  bool _buscando = false;
  String? _mensajeUbicacion;

  // Paso 4
  bool _guardando = false;
  String? _errorGeneral;

  // ---------- Lectura ----------
  int get paso => _paso;

  /// `true` si se está editando una parcela que ya existe.
  bool get esEdicion => _original != null;
  String get nombre => _nombre;
  Municipio? get municipio => _municipio;
  Cultivo? get cultivo => _cultivo;
  Etapa? get etapa => _etapa;
  bool get sinSembrar => _sinSembrar;
  double get latitud => _latitud;
  double get longitud => _longitud;
  bool get puntoPuesto => _puntoPuesto;
  bool get fueraDeJalapa => _fueraDeJalapa;
  String? get avisoPunto => _avisoPunto;
  String get altitudTexto => _altitudTexto;
  String get areaTexto => _areaTexto;
  String get unidadArea => _unidadArea;
  bool get ubicando => _ubicando;
  bool get buscando => _buscando;
  String? get mensajeUbicacion => _mensajeUbicacion;
  bool get guardando => _guardando;
  String? get errorGeneral => _errorGeneral;
  int? get altitud => int.tryParse(_altitudTexto.trim());
  double? get area => double.tryParse(_areaTexto.trim().replaceAll(',', '.'));

  /// Coordenadas con 4 decimales, como se muestran (HU-03).
  String get coordenadasTexto =>
      '${_latitud.toStringAsFixed(4)}, ${_longitud.toStringAsFixed(4)}';

  // ---------- Errores por paso (visibles tras intentar avanzar) ----------
  String? get errorNombre {
    if (!_intentoAvanzar || _paso != 1) return null;
    final limpio = _nombre.trim();
    if (limpio.isEmpty) return Textos.errorNombreParcelaVacio;
    if (!ParcelasServicio.nombreValido(limpio)) {
      return Textos.errorNombreParcelaLargo;
    }
    if (ParcelasServicio.nombreRepetido(limpio, _nombresUsados)) {
      return Textos.errorNombreParcelaRepetido;
    }
    return null;
  }

  bool get faltaMunicipio =>
      _intentoAvanzar && _paso == 1 && _municipio == null;

  bool get faltaCultivo =>
      _intentoAvanzar && _paso == 2 && _cultivo == null && !_sinSembrar;

  bool get faltaEtapa =>
      _intentoAvanzar && _paso == 2 && _cultivo != null && _etapa == null;

  bool get faltaPunto => _intentoAvanzar && _paso == 3 && !_puntoPuesto;

  String? get errorArea {
    if (_areaTexto.trim().isEmpty) return null;
    final valor = area;
    return valor == null || valor <= 0 ? Textos.errorArea : null;
  }

  String? get errorAltitud {
    if (_altitudTexto.trim().isEmpty) return null;
    final valor = altitud;
    return valor == null || valor < 0 ? Textos.errorAltura : null;
  }

  bool get _paso1Valido =>
      ParcelasServicio.nombreValido(_nombre) &&
      !ParcelasServicio.nombreRepetido(_nombre, _nombresUsados) &&
      _municipio != null;

  bool get _paso2Valido => _sinSembrar || (_cultivo != null && _etapa != null);

  bool get _paso3Valido =>
      _puntoPuesto &&
      !_fueraDeJalapa &&
      errorArea == null &&
      errorAltitud == null;

  bool _pasoValido(int paso) => switch (paso) {
    1 => _paso1Valido,
    2 => _paso2Valido,
    3 => _paso3Valido,
    _ => true,
  };

  // ---------- Paso 1 ----------
  void cambiarNombre(String valor) => _cambiar(() => _nombre = valor);

  void elegirMunicipio(Municipio valor) => _cambiar(() {
    _municipio = valor;
    // Si el punto ya puesto queda en otro municipio, hay que ponerlo de nuevo
    // (RN-02: el municipio guardado es el del punto).
    if (_puntoPuesto &&
        _parcelas.validacion.municipioDe(_latitud, _longitud) != valor) {
      _puntoPuesto = false;
      _avisoPunto = null;
      _fueraDeJalapa = false;
      if (_altitudDelGps) {
        _altitudTexto = '';
        _altitudDelGps = false;
      }
    }
    // Mientras no haya punto, el mapa se centra en el municipio elegido.
    if (!_puntoPuesto) {
      final centro = _parcelas.validacion.centro(valor);
      _latitud = centro.lat;
      _longitud = centro.lon;
    }
  });

  // ---------- Paso 2 ----------
  void elegirCultivo(Cultivo valor) => _cambiar(() {
    _cultivo = valor;
    _sinSembrar = false;
  });

  void elegirSinSembrar() => _cambiar(() {
    _sinSembrar = true;
    _cultivo = null;
    _etapa = null;
  });

  void elegirEtapa(Etapa valor) => _cambiar(() => _etapa = valor);

  // ---------- Paso 3 ----------
  /// El productor tocó el mapa o soltó el pin.
  void moverPin(double latitud, double longitud) => _cambiar(() {
    // Una altura del GPS ya no vale si el pin se va a otro lugar.
    if (_altitudDelGps) {
      _altitudTexto = '';
      _altitudDelGps = false;
    }
    _latitud = latitud;
    _longitud = longitud;
    _puntoPuesto = true;
    _mensajeUbicacion = null;
    final real = _parcelas.validacion.municipioDe(latitud, longitud);
    _fueraDeJalapa = real == null;
    if (real == null) {
      _avisoPunto = Textos.errorFueraDeJalapa;
    } else if (real != _municipio) {
      // Plans/02: se avisa y se usa el municipio real.
      _avisoPunto = Textos.avisoOtroMunicipio(Textos.municipio(real));
      _municipio = real;
    } else {
      _avisoPunto = null;
    }
  });

  /// HU-04: pone el pin donde está el teléfono.
  Future<void> usarMiUbicacion() async {
    if (_ubicando) return;
    _ubicando = true;
    _mensajeUbicacion = null;
    _avisar();
    final resultado = await _ubicacion.posicionActual();
    _ubicando = false;
    switch (resultado) {
      case UbicacionEncontrada(:final latitud, :final longitud, :final altitud):
        moverPin(latitud, longitud);
        if (altitud != null && _altitudTexto.trim().isEmpty) {
          _altitudTexto = '$altitud';
          _altitudDelGps = true;
        }
      case UbicacionSinPermiso():
        _mensajeUbicacion = Textos.sinPermisoUbicacion;
      case UbicacionApagada():
        _mensajeUbicacion = Textos.ubicacionApagada;
      case UbicacionNoDisponible():
        _mensajeUbicacion = Textos.sinUbicacion;
    }
    _avisar();
  }

  /// "Buscar aldea o lugar".
  Future<void> buscarLugar(String texto) async {
    if (_buscando || texto.trim().isEmpty) return;
    _buscando = true;
    _mensajeUbicacion = null;
    _avisar();
    final lugar = await _busqueda.buscar(texto);
    _buscando = false;
    if (lugar == null) {
      _mensajeUbicacion = Textos.sinResultados;
      _avisar();
    } else {
      moverPin(lugar.latitud, lugar.longitud);
    }
  }

  void cambiarAltitud(String valor) => _cambiar(() {
    _altitudTexto = valor;
    _altitudDelGps = false;
  });
  void cambiarArea(String valor) => _cambiar(() => _areaTexto = valor);
  void elegirUnidad(String unidad) => _cambiar(() => _unidadArea = unidad);

  // ---------- Navegación ----------
  /// "Siguiente". Devuelve `false` si el paso tiene algo pendiente.
  bool siguiente() {
    _intentoAvanzar = true;
    if (!_pasoValido(_paso)) {
      _avisar();
      return false;
    }
    _intentoAvanzar = false;
    if (_volverARevision) {
      // Vuelve a la revisión, salvo que otro paso haya quedado pendiente
      // (por ejemplo, el punto tras cambiar de municipio).
      _paso = [
        1,
        2,
        3,
      ].firstWhere((paso) => !_pasoValido(paso), orElse: () => totalPasos);
    } else {
      _paso = (_paso + 1).clamp(1, totalPasos);
    }
    if (_paso == totalPasos) _volverARevision = false;
    _avisar();
    return true;
  }

  /// "Atrás". Devuelve `false` si ya está en el primer paso (salir).
  bool atras() {
    if (esEdicion) {
      // Al editar, "atrás" desde un paso vuelve a la revisión y desde ahí sale.
      if (_paso == totalPasos) return false;
      _intentoAvanzar = false;
      _volverARevision = false;
      _paso = totalPasos;
      _avisar();
      return true;
    }
    if (_paso == 1) return false;
    _intentoAvanzar = false;
    _volverARevision = false;
    _paso--;
    _avisar();
    return true;
  }

  /// "Cambiar" en la revisión: va al paso y al terminar vuelve a revisar.
  void cambiarPaso(int paso) {
    _paso = paso.clamp(1, totalPasos - 1);
    _volverARevision = true;
    _intentoAvanzar = false;
    _avisar();
  }

  // ---------- Guardar ----------
  Future<ResultadoGuardado> guardar() async {
    if (_guardando) return ResultadoGuardado.error;
    _guardando = true;
    _errorGeneral = null;
    _avisar();
    try {
      final original = _original;
      final bool pendiente;
      if (original == null) {
        final guardada = await _parcelas.registrar(
          nombre: _nombre,
          latitud: _latitud,
          longitud: _longitud,
          cultivo: _sinSembrar ? null : _cultivo,
          etapa: _sinSembrar ? null : _etapa,
          altitud: altitud,
          area: area,
          unidadArea: _unidadArea,
        );
        pendiente = guardada.pendiente;
      } else {
        pendiente = await _parcelas.actualizar(
          original: original,
          nombre: _nombre,
          latitud: _latitud,
          longitud: _longitud,
          cultivo: _sinSembrar ? null : _cultivo,
          etapa: _sinSembrar ? null : _etapa,
          altitud: altitud,
          area: area,
          unidadArea: _unidadArea,
        );
      }
      return pendiente
          ? ResultadoGuardado.guardadaSinSenal
          : ResultadoGuardado.guardada;
    } on ErrorParcela catch (error) {
      switch (error.motivo) {
        case MotivoErrorParcela.nombreRepetido:
          _errorGeneral = Textos.errorNombreParcelaRepetido;
          _paso = 1;
          _volverARevision = true;
          _intentoAvanzar = true;
        case MotivoErrorParcela.fueraDeJalapa:
          _errorGeneral = Textos.errorFueraDeJalapa;
          _paso = 3;
          _volverARevision = true;
        case MotivoErrorParcela.sinSesion:
          _errorGeneral = Textos.errorGenerico;
      }
      return ResultadoGuardado.error;
    } catch (error) {
      debugPrint('Guardar parcela falló: $error');
      _errorGeneral = Textos.errorGenerico;
      return ResultadoGuardado.error;
    } finally {
      _guardando = false;
      _avisar();
    }
  }

  void _cargar(Parcela parcela) {
    _nombre = parcela.nombre;
    _municipio = parcela.municipio;
    _cultivo = parcela.cultivo;
    _etapa = parcela.etapa;
    _sinSembrar = parcela.cultivo == null;
    _latitud = parcela.latitud;
    _longitud = parcela.longitud;
    _puntoPuesto = true;
    _altitudTexto = parcela.altitud?.toString() ?? '';
    final area = parcela.area;
    _areaTexto = area == null
        ? ''
        : (area == area.roundToDouble() ? area.toInt().toString() : '$area');
    _unidadArea = parcela.unidadArea;
  }

  Future<void> _cargarNombres() async {
    try {
      final usados = await _parcelas.nombresUsados();
      // Al editar, su propio nombre no cuenta como repetido.
      _nombresUsados = [
        for (final usado in usados)
          if (usado != _original?.nombre) usado,
      ];
    } catch (error) {
      // Sin señal y sin copia local: se vuelve a revisar al guardar.
      debugPrint('No se cargaron los nombres de parcelas: $error');
    }
  }

  void _cambiar(void Function() cambio) {
    cambio();
    _errorGeneral = null;
    _avisar();
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
