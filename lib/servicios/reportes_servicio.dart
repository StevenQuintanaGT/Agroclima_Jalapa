import '../modelos/alerta.dart';
import '../modelos/enums.dart';
import '../modelos/parcela.dart';
import '../modelos/registro_dia.dart';
import '../repositorios/historial_repositorio.dart';
import '../utilidades/fechas.dart';

/// Días del calendario de un reporte, ambos incluidos.
class Periodo {
  const Periodo({required this.desde, required this.hasta});

  /// Los últimos [dias] días hasta hoy (en hora de Guatemala).
  factory Periodo.ultimosDias(int dias, DateTime ahora) {
    final hoy = _diaDe(Fechas.idDiario(ahora));
    return Periodo(
      desde: hoy.subtract(Duration(days: dias - 1)),
      hasta: hoy,
    );
  }

  /// Medianoche UTC del primer y del último día (fechas de calendario).
  final DateTime desde;
  final DateTime hasta;

  String get idDesde => _id(desde);
  String get idHasta => _id(hasta);
  int get cantidadDias => hasta.difference(desde).inDays + 1;

  /// Cada día del período, del primero al último.
  List<String> get ids => [
    for (var i = 0; i < cantidadDias; i++) _id(desde.add(Duration(days: i))),
  ];

  static DateTime _diaDe(String id) => DateTime.utc(
    int.parse(id.substring(0, 4)),
    int.parse(id.substring(4, 6)),
    int.parse(id.substring(6, 8)),
  );

  static String _id(DateTime dia) =>
      '${dia.year}${dia.month.toString().padLeft(2, '0')}'
      '${dia.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is Periodo && other.desde == desde && other.hasta == hasta;

  @override
  int get hashCode => Object.hash(desde, hasta);
}

/// Resumen de una parcela en un período (pantalla 25, HU-16).
class ResumenPeriodo {
  const ResumenPeriodo({
    required this.parcela,
    required this.periodo,
    required this.dias,
    required this.alertas,
  });

  final Parcela parcela;
  final Periodo periodo;

  /// Un registro por cada día del período; los días sin datos van vacíos.
  final List<RegistroDia> dias;

  /// Avisos de la parcela con día del evento en el período, sin repetir (si
  /// el riesgo empeoró ese día, el de nivel más alto), del más viejo al más nuevo.
  final List<Alerta> alertas;

  bool get hayDatos =>
      dias.any((d) => d.temperatura != null || d.precipitacion != null);

  /// Días con lluvia: 1 mm o más (igual que el motor y el historial).
  int get diasConLluvia =>
      dias.where((d) => (d.precipitacion ?? 0) >= 1).length;

  /// Lluvia acumulada del período (mm).
  double get lluviaTotal =>
      dias.fold(0, (suma, d) => suma + (d.precipitacion ?? 0));

  /// Mínima de cada día: la observada por el ciclo o, si no, la registrada.
  static double? minimaDe(RegistroDia d) =>
      d.temperaturaMinima ?? d.temperatura;
  static double? maximaDe(RegistroDia d) =>
      d.temperaturaMaxima ?? d.temperatura;

  /// La noche más fría (mínima más baja) y su día; `null` si no hay datos.
  /// Si algún día tiene la mínima y la máxima del ciclo (D-53), los extremos
  /// salen solo de esos días: una temperatura suelta (p. ej. la de hoy a
  /// mediodía) no es la mínima de la noche.
  bool get hayExtremos => dias.any(
    (d) => d.temperaturaMinima != null && d.temperaturaMaxima != null,
  );

  RegistroDia? get nocheMasFria => _extremo(
    hayExtremos ? (d) => d.temperaturaMinima : minimaDe,
    (a, b) => a < b,
  );
  RegistroDia? get diaMasCaliente => _extremo(
    hayExtremos ? (d) => d.temperaturaMaxima : maximaDe,
    (a, b) => a > b,
  );

  /// El día que más llovió (con al menos 1 mm).
  RegistroDia? get diaMasLluvioso {
    RegistroDia? mayor;
    for (final d in dias) {
      if ((d.precipitacion ?? 0) < 1) continue;
      if (mayor == null || d.precipitacion! > mayor.precipitacion!) mayor = d;
    }
    return mayor;
  }

  /// Avisos de PELIGRO del período.
  int get avisosPeligro =>
      alertas.where((a) => a.nivel == NivelSeveridad.critica).length;

  /// Nivel más alto de los avisos de un día, si hubo.
  NivelSeveridad? nivelDelDia(String fecha) {
    NivelSeveridad? nivel;
    for (final a in alertas) {
      if (Fechas.idDiario(a.fechaEvento) != fecha) continue;
      if (nivel == null || a.nivel.index > nivel.index) nivel = a.nivel;
    }
    return nivel;
  }

  RegistroDia? _extremo(
    double? Function(RegistroDia) valor,
    bool Function(double, double) mejor,
  ) {
    RegistroDia? elegido;
    for (final d in dias) {
      final v = valor(d);
      if (v == null) continue;
      if (elegido == null || mejor(v, valor(elegido)!)) elegido = d;
    }
    return elegido;
  }
}

/// Reportes (CO-17, HU-16): resume lo ya guardado, sin llamar a OpenWeather.
class ReportesServicio {
  ReportesServicio(this._historial);

  final HistorialRepositorio _historial;

  Stream<List<RegistroDia>> registros(String parcelaId, Periodo periodo) =>
      _historial.rango(
        parcelaId,
        desde: periodo.idDesde,
        hasta: periodo.idHasta,
      );

  static ResumenPeriodo calcular({
    required Parcela parcela,
    required Periodo periodo,
    required List<RegistroDia> registros,
    required List<Alerta> alertas,
  }) {
    final porFecha = {for (final r in registros) r.fecha: r};
    final dentro = periodo.ids.toSet();
    final unicas = <String, Alerta>{};
    for (final a in alertas) {
      final dia = Fechas.idDiario(a.fechaEvento);
      if (a.parcelaId != parcela.parcelaId || !dentro.contains(dia)) continue;
      final clave = '${a.tipoRiesgo.valor}|$dia';
      final otra = unicas[clave];
      if (otra == null || a.nivel.index > otra.nivel.index) unicas[clave] = a;
    }
    return ResumenPeriodo(
      parcela: parcela,
      periodo: periodo,
      dias: [
        for (final id in periodo.ids) porFecha[id] ?? RegistroDia(fecha: id),
      ],
      alertas: unicas.values.toList()
        ..sort((a, b) => a.fechaEvento.compareTo(b.fechaEvento)),
    );
  }

  /// `agroclima_el-guayabal_20261004_20261010` (sin tildes ni espacios).
  static String nombreArchivo(ResumenPeriodo r) {
    const tildes = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    final nombre = r.parcela.nombre
        .toLowerCase()
        .split('')
        .map((c) => tildes[c] ?? c)
        .join()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return 'agroclima_${nombre}_${r.periodo.idDesde}_${r.periodo.idHasta}';
  }
}
