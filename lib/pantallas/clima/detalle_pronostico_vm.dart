import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../modelos/clima_actual.dart';
import '../../modelos/franja_pronostico.dart';
import '../../modelos/parcela.dart';
import '../../modelos/pronostico_dia.dart';
import '../../modelos/resumen_dia.dart';
import '../../servicios/clima_servicio.dart';
import '../../servicios/parcelas_servicio.dart';
import '../../utilidades/fechas.dart';

/// Detalle de pronóstico (pantalla 19, HU-08). Usa lo que el panel ya dejó
/// en la caché: abrirlo no gasta consultas si el pronóstico sigue vigente.
class DetallePronosticoVm extends ChangeNotifier {
  DetallePronosticoVm({
    required this._parcelas,
    required this._clima,
    required this.parcelaId,
    String? diaInicial,
    DateTime Function()? reloj,
  }) : _fechaElegida = diaInicial,
       _reloj = reloj ?? DateTime.now {
    _suscripcionParcela = _parcelas.observar(parcelaId).listen((parcela) {
      final primera = _parcela == null && parcela != null;
      _parcela = parcela;
      if (primera) _cargar(parcela);
      if (parcela == null) _cargando = false;
      _avisar();
    }, onError: (Object e) => debugPrint('Parcela del pronóstico: $e'));
    _suscripcionDias = _clima.proximosDias(parcelaId).listen((dias) {
      _guardados = dias;
      _avisar();
    }, onError: (Object e) => debugPrint('Próximos días: $e'));
  }

  final ParcelasServicio _parcelas;
  final ClimaServicio _clima;
  final String parcelaId;
  final DateTime Function() _reloj;

  late final StreamSubscription<Parcela?> _suscripcionParcela;
  late final StreamSubscription<List<PronosticoDia>> _suscripcionDias;
  bool _descartado = false;

  Parcela? _parcela;
  ClimaActual? _actual;
  List<FranjaPronostico> _franjas = const [];
  List<PronosticoDia> _guardados = const [];
  String? _fechaElegida;
  bool _cargando = true;

  bool get cargando => _cargando;
  Parcela? get parcela => _parcela;

  List<ResumenDia> get dias => ClimaServicio.dias(
    franjas: _franjas,
    guardados: _guardados,
    ahora: _reloj().toUtc(),
    actual: _actual,
  );

  /// Día que se está viendo (hoy si no se eligió otro o ya pasó).
  ResumenDia? get dia {
    final lista = dias;
    if (lista.isEmpty) return null;
    return lista.firstWhere(
      (d) => d.fecha == _fechaElegida,
      orElse: () => lista.first,
    );
  }

  bool get esHoy => dia?.fecha == Fechas.idDiario(_reloj().toUtc());

  /// Salida y puesta del sol: solo se conocen las de hoy.
  ClimaActual? get solDeHoy => esHoy ? _actual : null;

  /// Franja más fría del día que se ve (para "Lo más frío será…").
  FranjaPronostico? get masFria {
    final franjas = dia?.franjas ?? const [];
    if (franjas.isEmpty) return null;
    return franjas.reduce((a, b) => b.temperatura < a.temperatura ? b : a);
  }

  FranjaPronostico? get masCaliente {
    final franjas = dia?.franjas ?? const [];
    if (franjas.isEmpty) return null;
    return franjas.reduce((a, b) => b.temperatura > a.temperatura ? b : a);
  }

  void elegir(ResumenDia dia) {
    _fechaElegida = dia.fecha;
    _avisar();
  }

  Future<void> _cargar(Parcela parcela) async {
    final resultados = await Future.wait([
      _clima.porHoras(parcela),
      _clima.actual(parcela),
    ]);
    _franjas = (resultados[0].dato as List<FranjaPronostico>?) ?? const [];
    _actual = resultados[1].dato as ClimaActual?;
    _cargando = false;
    _avisar();
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _suscripcionParcela.cancel();
    _suscripcionDias.cancel();
    super.dispose();
  }
}
