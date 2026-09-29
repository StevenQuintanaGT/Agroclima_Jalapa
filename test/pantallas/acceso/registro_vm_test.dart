import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/pantallas/acceso/registro_vm.dart';
import 'package:agroclima_jalapa/repositorios/auth_repositorio.dart';
import 'package:agroclima_jalapa/servicios/cuenta_servicio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _CuentaFalsa extends Mock implements CuentaServicio {}

void _llenarValido(RegistroVm vm) {
  vm
    ..cambiarNombre('Juan López García')
    ..cambiarTelefono('5512 3456')
    ..cambiarCorreo('juan.lopez@correo.com')
    ..cambiarContrasena('siembra2026')
    ..cambiarRepetir('siembra2026')
    ..cambiarTerminos(true);
}

void main() {
  late _CuentaFalsa cuenta;
  late RegistroVm vm;

  void registrarResponde(Future<void> Function() respuesta) {
    when(
      () => cuenta.registrar(
        nombre: any(named: 'nombre'),
        telefono: any(named: 'telefono'),
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
      ),
    ).thenAnswer((_) => respuesta());
  }

  setUp(() {
    cuenta = _CuentaFalsa();
    vm = RegistroVm(cuenta);
  });

  test('sin aceptar términos no se puede enviar', () {
    _llenarValido(vm);
    vm.cambiarTerminos(false);
    expect(vm.puedeEnviar, isFalse);
  });

  test('antes de enviar no se muestran errores, solo lo válido', () {
    vm.cambiarCorreo('juan@');
    expect(vm.errorCorreo, isNull);
    expect(vm.correoValido, isFalse);
    vm.cambiarCorreo('juan@correo.com');
    expect(vm.correoValido, isTrue);
  });

  test(
    'formulario con errores: muestra errores y no llama al servicio',
    () async {
      vm
        ..cambiarCorreo('juan@')
        ..cambiarContrasena('corta')
        ..cambiarRepetir('otra')
        ..cambiarTerminos(true);

      expect(await vm.registrar(), isFalse);
      expect(vm.errorNombre, Textos.errorNombreVacio);
      expect(vm.errorCorreo, Textos.errorCorreo);
      expect(vm.errorContrasena, Textos.errorContrasenaCorta);
      expect(vm.errorRepetir, Textos.errorContrasenasDistintas);
      verifyNever(
        () => cuenta.registrar(
          nombre: any(named: 'nombre'),
          telefono: any(named: 'telefono'),
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
        ),
      );
    },
  );

  test(
    'formulario válido: registra con teléfono +502 y datos limpios',
    () async {
      registrarResponde(() async {});
      _llenarValido(vm);
      vm.cambiarNombre('  Juan López García  ');

      expect(await vm.registrar(), isTrue);
      verify(
        () => cuenta.registrar(
          nombre: 'Juan López García',
          telefono: '+50255123456',
          correo: 'juan.lopez@correo.com',
          contrasena: 'siembra2026',
        ),
      ).called(1);
      expect(vm.cargando, isFalse);
    },
  );

  test('sin señal: mensaje llano y se conserva lo escrito', () async {
    registrarResponde(
      () async => throw const ErrorAcceso('network-request-failed'),
    );
    _llenarValido(vm);

    expect(await vm.registrar(), isFalse);
    expect(vm.errorGeneral, Textos.errorSinSenal);
    expect(vm.correoValido, isTrue);
    expect(vm.repetirValida, isTrue);
    expect(vm.puedeEnviar, isTrue);
  });

  test('correo ya usado: lo dice en palabras', () async {
    registrarResponde(
      () async => throw const ErrorAcceso('email-already-in-use'),
    );
    _llenarValido(vm);
    await vm.registrar();
    expect(vm.errorGeneral, Textos.errorCorreoEnUso);
  });

  test('al corregir un campo se quita el error general', () async {
    registrarResponde(() async => throw const ErrorAcceso('too-many-requests'));
    _llenarValido(vm);
    await vm.registrar();
    expect(vm.errorGeneral, isNotNull);
    vm.cambiarCorreo('otro@correo.com');
    expect(vm.errorGeneral, isNull);
  });

  test('errores inesperados no muestran códigos', () async {
    registrarResponde(() async => throw StateError('algo interno'));
    _llenarValido(vm);
    await vm.registrar();
    expect(vm.errorGeneral, Textos.errorGenerico);
  });
}
