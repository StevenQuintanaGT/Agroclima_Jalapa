import 'package:agroclima_jalapa/utilidades/fechas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fechas.idDiario', () {
    test('usa la hora de Guatemala (UTC-6)', () {
      // 05:59 UTC del 15 = 23:59 del 14 en Guatemala.
      expect(Fechas.idDiario(DateTime.utc(2026, 3, 15, 5, 59)), '20260314');
      // 06:00 UTC del 15 = 00:00 del 15 en Guatemala.
      expect(Fechas.idDiario(DateTime.utc(2026, 3, 15, 6)), '20260315');
    });

    test('rellena mes y día con cero', () {
      expect(Fechas.idDiario(DateTime.utc(2026, 1, 5, 12)), '20260105');
    });

    test('cambio de año', () {
      expect(Fechas.idDiario(DateTime.utc(2027, 1, 1, 3)), '20261231');
    });

    test('no depende de la zona del teléfono', () {
      final instante = DateTime.utc(2026, 7, 20, 2);
      expect(Fechas.idDiario(instante.toLocal()), Fechas.idDiario(instante));
    });
  });

  test('aHoraGuatemala resta 6 horas', () {
    final local = Fechas.aHoraGuatemala(DateTime.utc(2026, 7, 20, 14, 30));
    expect(local.hour, 8);
    expect(local.minute, 30);
  });
}
