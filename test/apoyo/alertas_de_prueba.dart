import 'package:agroclima_jalapa/modelos/alerta.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';

/// Lunes 5 de octubre de 2026, 9:00 en Guatemala.
final ahoraDePrueba = DateTime.utc(2026, 10, 5, 15);

/// 00:00 en Guatemala del día [dia] de octubre de 2026.
DateTime eventoDe(int dia) => DateTime.utc(2026, 10, dia, 6);

Alerta alertaDePrueba({
  String id = 'a1',
  String parcelaId = 'joya',
  TipoRiesgo tipo = TipoRiesgo.temperaturaBaja,
  NivelSeveridad nivel = NivelSeveridad.critica,
  double esperado = -1,
  double umbral = 0,
  int dia = 6,
  bool leida = false,
  bool atendida = false,
  Cultivo? cultivo = Cultivo.cafe,
  int? diasConsecutivos,
  String medida = 'Proteja el almácigo durante la noche. Riegue por la tarde: el suelo húmedo guarda mejor el calor.',
}) => Alerta(
  alertaId: id,
  usuarioId: 'ana',
  parcelaId: parcelaId,
  tipoRiesgo: tipo,
  nivel: nivel,
  valorEsperado: esperado,
  valorUmbral: umbral,
  mensaje: 'Mañana en la madrugada puede bajar a -1 °C. Proteja el almácigo.',
  medidaSugerida: medida,
  fechaEvento: eventoDe(dia),
  fechaGeneracion: ahoraDePrueba,
  leida: leida,
  atendida: atendida,
  parcelaNombre: 'La Joya',
  cultivo: cultivo,
  diasConsecutivos: diasConsecutivos,
);
