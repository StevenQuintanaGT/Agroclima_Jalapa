import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/pantallas/acceso/bienvenida_vm.dart';
import 'package:agroclima_jalapa/pantallas/acceso/inicio_sesion_vm.dart';
import 'package:agroclima_jalapa/pantallas/acceso/permiso_vm.dart';
import 'package:agroclima_jalapa/pantallas/acceso/recuperar_contrasena_vm.dart';
import 'package:agroclima_jalapa/repositorios/auth_repositorio.dart';
import 'package:agroclima_jalapa/servicios/cuenta_servicio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../apoyo/preferencias_falsas.dart';

class _CuentaFalsa extends Mock implements CuentaServicio {}

void main() {
  late _CuentaFalsa cuenta;

  setUp(() => cuenta = _CuentaFalsa());

  group('InicioSesionVm', () {
    void entrarResponde(Future<void> Function() respuesta) {
      when(
        () => cuenta.iniciarSesion(
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
        ),
      ).thenAnswer((_) => respuesta());
    }

    test('campos vacíos: errores llanos y no llama al servicio', () async {
      final vm = InicioSesionVm(cuenta);
      expect(await vm.entrar(), isFalse);
      expect(vm.errorCorreo, Textos.errorCorreo);
      expect(vm.errorContrasena, Textos.errorContrasenaVacia);
      verifyNever(
        () => cuenta.iniciarSesion(
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
        ),
      );
    });

    test('credenciales correctas: entra con el correo limpio', () async {
      entrarResponde(() async {});
      final vm = InicioSesionVm(cuenta)
        ..cambiarCorreo(' ana@correo.com ')
        ..cambiarContrasena('clave1234');
      expect(await vm.entrar(), isTrue);
      verify(
        () => cuenta.iniciarSesion(
          correo: 'ana@correo.com',
          contrasena: 'clave1234',
        ),
      ).called(1);
    });

    test('credenciales malas: mensaje llano', () async {
      entrarResponde(() async => throw const ErrorAcceso('invalid-credential'));
      final vm = InicioSesionVm(cuenta)
        ..cambiarCorreo('ana@correo.com')
        ..cambiarContrasena('mala');
      expect(await vm.entrar(), isFalse);
      expect(vm.errorGeneral, Textos.errorCredenciales);
    });

    test('Google cancelado no muestra error', () async {
      when(() => cuenta.iniciarSesionConGoogle())
          .thenThrow(const ErrorAcceso(ErrorAcceso.cancelado));
      final vm = InicioSesionVm(cuenta);
      expect(await vm.entrarConGoogle(), isFalse);
      expect(vm.errorGeneral, isNull);
      expect(vm.cargandoGoogle, isFalse);
    });

    test('Google mal configurado: mensaje llano', () async {
      when(() => cuenta.iniciarSesionConGoogle())
          .thenThrow(const ErrorAcceso('google-clientConfigurationError'));
      final vm = InicioSesionVm(cuenta);
      await vm.entrarConGoogle();
      expect(vm.errorGeneral, Textos.errorGoogle);
    });
  });

  group('RecuperarContrasenaVm', () {
    test('correo mal escrito no envía', () async {
      final vm = RecuperarContrasenaVm(cuenta)..cambiarCorreo('ana@');
      await vm.enviar();
      expect(vm.errorCorreo, Textos.errorCorreo);
      expect(vm.enviado, isFalse);
      verifyNever(() => cuenta.recuperarContrasena(any()));
    });

    test('envía y confirma en la misma pantalla', () async {
      when(() => cuenta.recuperarContrasena(any())).thenAnswer((_) async {});
      final vm = RecuperarContrasenaVm(cuenta)..cambiarCorreo('ana@correo.com');
      await vm.enviar();
      expect(vm.enviado, isTrue);
      verify(() => cuenta.recuperarContrasena('ana@correo.com')).called(1);
    });

    test('sin señal: lo dice y no confirma', () async {
      when(() => cuenta.recuperarContrasena(any()))
          .thenThrow(const ErrorAcceso('network-request-failed'));
      final vm = RecuperarContrasenaVm(cuenta)..cambiarCorreo('ana@correo.com');
      await vm.enviar();
      expect(vm.enviado, isFalse);
      expect(vm.errorGeneral, Textos.errorSinSenal);
    });
  });

  group('PermisoVm', () {
    test('"Permitir" pide el permiso del sistema', () async {
      var pedidos = 0;
      final vm = PermisoVm(
        pedirPermiso: () async {
          pedidos++;
          return false;
        },
        preferencias: PreferenciasFalsas(),
        esUltimo: false,
      );
      await vm.permitir();
      expect(pedidos, 1);
      expect(vm.pidiendo, isFalse);
    });

    test('"Ahora no" no pide nada', () async {
      var pedidos = 0;
      final preferencias = PreferenciasFalsas();
      final vm = PermisoVm(
        pedirPermiso: () async {
          pedidos++;
          return true;
        },
        preferencias: preferencias,
        esUltimo: true,
      );
      await vm.ahoraNo();
      expect(pedidos, 0);
      // Aun así no se vuelven a ofrecer al entrar (RNF-05).
      expect(preferencias.permisosOfrecidos, isTrue);
    });

    test('solo la última pantalla marca los permisos como ofrecidos', () async {
      final preferencias = PreferenciasFalsas();
      final vm = PermisoVm(
        pedirPermiso: () async => true,
        preferencias: preferencias,
        esUltimo: false,
      );
      await vm.permitir();
      expect(preferencias.permisosOfrecidos, isFalse);
    });

    test('si pedir el permiso falla, igual continúa', () async {
      final preferencias = PreferenciasFalsas();
      final vm = PermisoVm(
        pedirPermiso: () async => throw StateError('sin actividad'),
        preferencias: preferencias,
        esUltimo: true,
      );
      await vm.permitir();
      expect(preferencias.permisosOfrecidos, isTrue);
    });
  });

  group('BienvenidaVm', () {
    test('avanza entre los 3 pasos y marca la bienvenida vista', () async {
      final preferencias = PreferenciasFalsas();
      final vm = BienvenidaVm(preferencias);
      expect(vm.esUltimo, isFalse);
      vm.irAPaso(2);
      expect(vm.esUltimo, isTrue);
      await vm.terminar();
      expect(preferencias.bienvenidaVista, isTrue);
    });
  });
}
