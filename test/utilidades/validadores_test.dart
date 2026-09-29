import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/utilidades/errores.dart';
import 'package:agroclima_jalapa/utilidades/validadores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VA-04 correo', () {
    test('acepta correos bien escritos', () {
      expect(Validadores.correo('juan.lopez@correo.com'), isNull);
      expect(Validadores.correo('  ana@gmail.com '), isNull);
    });

    test('rechaza correos mal escritos con mensaje llano', () {
      for (final malo in ['', 'juan', 'juan@', 'juan@correo', 'a b@c.com']) {
        expect(Validadores.correo(malo), Textos.errorCorreo, reason: malo);
      }
    });
  });

  group('VA-05 contraseña', () {
    test('mínimo 8 caracteres', () {
      expect(Validadores.contrasena('1234567'), Textos.errorContrasenaCorta);
      expect(Validadores.contrasena('12345678'), isNull);
    });

    test('repetir debe coincidir', () {
      expect(Validadores.repetirContrasena('abcdefgh', 'abcdefgh'), isNull);
      expect(
        Validadores.repetirContrasena('abcdefgx', 'abcdefgh'),
        Textos.errorContrasenasDistintas,
      );
    });
  });

  test('nombre obligatorio', () {
    expect(Validadores.nombre('   '), Textos.errorNombreVacio);
    expect(Validadores.nombre('Juan López'), isNull);
  });

  group('teléfono (opcional, +502 y 8 números)', () {
    test('vacío o con 8 números es válido', () {
      expect(Validadores.telefono(''), isNull);
      expect(Validadores.telefono('5512 3456'), isNull);
      expect(Validadores.telefono('5512-3456'), isNull);
    });

    test('con otra cantidad de números no es válido', () {
      expect(Validadores.telefono('5512 345'), Textos.errorTelefono);
      expect(Validadores.telefono('551234567'), Textos.errorTelefono);
    });

    test('se guarda con código de país', () {
      expect(Validadores.telefonoConCodigo('5512 3456'), '+50255123456');
      expect(Validadores.telefonoConCodigo(''), '');
    });
  });

  group('Errores.deAcceso', () {
    test('traduce los códigos de Firebase del plan', () {
      expect(Errores.deAcceso('email-already-in-use'), Textos.errorCorreoEnUso);
      expect(Errores.deAcceso('wrong-password'), Textos.errorCredenciales);
      expect(Errores.deAcceso('invalid-credential'), Textos.errorCredenciales);
      expect(Errores.deAcceso('weak-password'), Textos.errorContrasenaDebil);
      expect(Errores.deAcceso('network-request-failed'), Textos.errorSinSenal);
      expect(Errores.deAcceso('too-many-requests'), Textos.errorMuchosIntentos);
      expect(Errores.deAcceso('invalid-email'), Textos.errorCorreo);
    });

    test('nunca muestra el código: lo desconocido da el mensaje general', () {
      expect(Errores.deAcceso('internal-error'), Textos.errorGenerico);
    });
  });
}
