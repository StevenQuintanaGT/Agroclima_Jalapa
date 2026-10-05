import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../modelos/clima_actual.dart';
import '../../modelos/condicion.dart';
import '../../modelos/franja_pronostico.dart';
import '../../modelos/parcela.dart';
import '../../modelos/pronostico_dia.dart';
import '../../modelos/resultado.dart';
import '../../modelos/resumen_dia.dart';
import '../../repositorios/preferencias_locales_repositorio.dart';
import '../../servicios/clima_servicio.dart';
import '../../servicios/conectividad_servicio.dart';
import '../../servicios/parcelas_servicio.dart';

/// Panel principal (pantallas 17 y 18, HU-07): clima de la parcela elegida,
/// con caché primero y aviso de "no vigente". Sin conexión muestra lo
/// guardado y, al volver la señal o la app, se actualiza solo (HU-15).
class PanelVm extends ChangeNotifier {
  PanelVm({
    required this._parcelas,
    required this._clima,
    required this._preferencias,
    this._conectividad,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now {
    final conectividad = _conectividad;
    if (conectividad != null) {
      conectividad.hayRed().then((hay) {
        _enLinea = hay;
        _avisar();
      }, onError: (Object e) => debugPrint('Conectividad: $e'));
      _suscripcionRed = conectividad.cambios.listen(
        _alCambiarRed,
        onError: (Object e) => debugPrint('Conectividad: $e'),
      );
    }
    _suscripcionParcelas = _parcelas.misParcelas().listen(
      _alCambiarParcelas,
      onError: (Object error) {
        debugPrint('No se pudieron leer las parcelas: $error');
        _cargandoParcelas = false;
        _avisar();
      },
    );
  }

  final ParcelasServicio _parcelas;
  final ClimaServicio _clima;
  final PreferenciasLocalesRepositorio _preferencias;
  final ConectividadServicio? _conectividad;
  final DateTime Function() _reloj;

  late final StreamSubscription<List<Parcela>> _suscripcionParcelas;
  StreamSubscription<Condicion?>? _suscripcionCondicion;
  StreamSubscription<List<PronosticoDia>>? _suscripcionDias;
  StreamSubscription<bool>? _suscripcionRed;
  bool _descartado = false;

  /// Evita mostrar el clima de una parcela que ya no está elegida.
  int _consulta = 0;

  List<Parcela> _lista = const [];
  bool _cargandoParcelas = true;
  Parcela? _parcela;

  Resultado<ClimaActual>? _actual;
  Resultado<List<FranjaPronostico>>? _horas;
  Condicion? _condicionHoy;
  List<PronosticoDia> _dias = const [];
  bool _cargandoClima = false;
  bool _enLinea = true;

  // ---------- Lectura ----------
  List<Parcela> get parcelas => _lista;
  Parcela? get parcela => _parcela;
  bool get cargandoParcelas => _cargandoParcelas;
  bool get sinParcelas => !_cargandoParcelas && _lista.isEmpty;
  bool get variasParcelas => _lista.length > 1;

  /// Cargando por primera vez (sin nada que mostrar todavía).
  bool get cargandoClima => _cargandoClima && _actual?.dato == null;

  /// Actualizando con algo ya en pantalla.
  bool get actualizando => _cargandoClima && _actual?.dato != null;
  Resultado<ClimaActual>? get actual => _actual;
  ClimaActual? get clima => _actual?.dato;
  bool get vigente => _actual?.vigente ?? false;

  /// `false` si el teléfono no tiene ninguna red (banner de la pantalla 32).
  bool get enLinea => _enLinea;
  List<FranjaPronostico> get franjas => _horas?.dato ?? const [];
  List<PronosticoDia> get proximosDias => _dias;

  PronosticoDia? get hoy => ClimaServicio.hoy(
    guardados: _dias,
    franjas: franjas,
    ahora: _reloj().toUtc(),
    actual: clima,
  );

  /// "Los próximos días" (HU-08), de hoy en adelante.
  List<ResumenDia> get dias => ClimaServicio.dias(
    franjas: franjas,
    guardados: _dias,
    ahora: _reloj().toUtc(),
    actual: clima,
  );

  /// "Hoy, hora por hora": las franjas de las próximas 21 horas.
  List<FranjaPronostico> get proximasHoras {
    final ahora = _reloj().toUtc();
    return franjas.where((f) => f.fechaHora.isAfter(ahora)).take(7).toList();
  }

  double? get probabilidadLluvia =>
      ClimaServicio.probabilidadLluvia(franjas, _reloj().toUtc());

  /// mm del día que calcula el ciclo (D-40); `null` si aún no pasó hoy.
  double? get lluviaHoy => _condicionHoy?.precipitacion;

  /// Tiempo desde la última actualización del dato mostrado.
  Duration? get antiguedad {
    final fecha = _actual?.fecha;
    return fecha == null ? null : _reloj().toUtc().difference(fecha);
  }

  // ---------- Acciones ----------
  Future<void> elegir(Parcela parcela) async {
    if (parcela.parcelaId == _parcela?.parcelaId) return;
    unawaited(_preferencias.elegirParcela(parcela.parcelaId));
    _mostrar(parcela);
  }

  /// "Intentar de nuevo" y deslizar hacia abajo: va a la red aunque lo
  /// guardado siga vigente.
  Future<void> actualizar() => _cargar(forzar: true);

  /// La app vuelve a primer plano: se revisa la vigencia (caché primero; no
  /// gasta consultas si el dato sigue vigente).
  Future<void> alVolverALaApp() async {
    if (_parcela != null && !_cargandoClima) await _cargar();
  }

  // ---------- Interno ----------
  void _alCambiarRed(bool hayRed) {
    final volvio = hayRed && !_enLinea;
    _enLinea = hayRed;
    _avisar();
    // Al volver la señal se actualiza solo lo que quedó vencido o con error.
    final pendiente =
        !vigente || _actual?.error != null || _horas?.vigente == false;
    if (volvio && pendiente && _parcela != null && !_cargandoClima) {
      _cargar();
    }
  }

  void _alCambiarParcelas(List<Parcela> lista) {
    _lista = lista;
    _cargandoParcelas = false;
    if (lista.isEmpty) {
      _parcela = null;
      _avisar();
      return;
    }
    final actualId = _parcela?.parcelaId ?? _preferencias.parcelaSeleccionada;
    final elegida = lista.firstWhere(
      (p) => p.parcelaId == actualId,
      orElse: () => lista.first,
    );
    final cambioPunto =
        _parcela == null ||
        elegida.parcelaId != _parcela!.parcelaId ||
        elegida.celdaClima != _parcela!.celdaClima;
    if (cambioPunto) {
      _mostrar(elegida);
    } else {
      // Mismo punto (p. ej. cambió el nombre): solo se refresca el encabezado.
      _parcela = elegida;
      _avisar();
    }
  }

  void _mostrar(Parcela parcela) {
    _parcela = parcela;
    _actual = null;
    _horas = null;
    _condicionHoy = null;
    _dias = const [];
    _suscripcionCondicion?.cancel();
    _suscripcionDias?.cancel();
    _suscripcionCondicion = _clima.condicionDeHoy(parcela.parcelaId).listen((
      condicion,
    ) {
      _condicionHoy = condicion;
      _avisar();
    }, onError: (Object e) => debugPrint('Condición de hoy: $e'));
    _suscripcionDias = _clima.proximosDias(parcela.parcelaId).listen((dias) {
      _dias = dias;
      _avisar();
    }, onError: (Object e) => debugPrint('Próximos días: $e'));
    _cargar();
  }

  Future<void> _cargar({bool forzar = false}) async {
    final parcela = _parcela;
    if (parcela == null) return;
    final consulta = ++_consulta;
    _cargandoClima = true;
    _avisar();
    final resultados = await Future.wait([
      _clima.actual(parcela, forzar: forzar),
      _clima.porHoras(parcela, forzar: forzar),
    ]);
    if (consulta != _consulta) return;
    _actual = resultados[0] as Resultado<ClimaActual>;
    _horas = resultados[1] as Resultado<List<FranjaPronostico>>;
    _cargandoClima = false;
    _avisar();
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _suscripcionParcelas.cancel();
    _suscripcionCondicion?.cancel();
    _suscripcionDias?.cancel();
    _suscripcionRed?.cancel();
    super.dispose();
  }
}
