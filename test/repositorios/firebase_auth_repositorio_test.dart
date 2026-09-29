import 'package:agroclima_jalapa/repositorios/firebase_auth_repositorio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('codigoDeAcceso', () {
    test('los códigos conocidos pasan tal cual', () {
      expect(
        codigoDeAcceso('email-already-in-use', 'x'),
        'email-already-in-use',
      );
      expect(
        codigoDeAcceso('network-request-failed', null),
        'network-request-failed',
      );
    });

    test('"unknown" por falta de conexión se trata como sin señal', () {
      expect(
        codigoDeAcceso(
          'unknown',
          'An internal error has occurred. [ Failed to connect to /10.0.2.2:9099 ]',
        ),
        'network-request-failed',
      );
      expect(
        codigoDeAcceso('internal-error', 'Unable to resolve host "x"'),
        'network-request-failed',
      );
    });

    test('"unknown" por otra causa sigue siendo desconocido', () {
      expect(codigoDeAcceso('unknown', 'Algo raro'), 'unknown');
      expect(codigoDeAcceso('unknown', null), 'unknown');
    });
  });
}
