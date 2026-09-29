import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/pantallas/acceso/registro_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/acceso/registro_vm.dart';
import 'package:agroclima_jalapa/repositorios/auth_repositorio.dart';
import 'package:agroclima_jalapa/servicios/cuenta_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _CuentaFalsa extends Mock implements CuentaServicio {}

Future<void> _abrir(WidgetTester tester, CuentaServicio cuenta) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: TemaApp.claro,
      home: ChangeNotifierProvider(
        create: (_) => RegistroVm(cuenta),
        child: const RegistroPantalla(),
      ),
    ),
  );
}

Finder _campo(String etiqueta) => find.descendant(
  of: find
      .ancestor(of: find.text(etiqueta), matching: find.byType(Column))
      .first,
  matching: find.byType(TextFormField),
);

Future<void> _escribir(
  WidgetTester tester,
  String etiqueta,
  String texto,
) async {
  await tester.enterText(_campo(etiqueta), texto);
  await tester.pump();
}

Future<void> _tocarCrear(WidgetTester tester) async {
  await tester.ensureVisible(find.text(Textos.crearMiCuenta));
  await tester.tap(find.text(Textos.crearMiCuenta));
  await tester.pump();
}

void main() {
  pruebasFoco();

  testWidgets('muestra los campos del diseño y la ayuda de contraseña', (
    tester,
  ) async {
    await _abrir(tester, _CuentaFalsa());
    for (final etiqueta in [
      Textos.nombreCompleto,
      Textos.telefono,
      Textos.correo,
      Textos.creeContrasena,
      Textos.repetirContrasena,
    ]) {
      expect(find.text(etiqueta), findsOneWidget);
    }
    expect(find.text(Textos.prefijoGuatemala), findsOneWidget);
    expect(find.text(Textos.ayudaContrasena), findsOneWidget);
  });

  testWidgets('el botón se habilita al aceptar los términos', (tester) async {
    await _abrir(tester, _CuentaFalsa());
    FilledButton boton() => tester.widget(find.byType(FilledButton));
    expect(boton().onPressed, isNull);

    await tester.ensureVisible(
      find.textContaining(Textos.terminosDeUso, findRichText: true),
    );
    await tester.tap(
      find.textContaining(Textos.terminosDeUso, findRichText: true),
    );
    await tester.pump();
    expect(boton().onPressed, isNotNull);
  });

  testWidgets('al enviar con errores se ven bajo cada campo', (tester) async {
    await _abrir(tester, _CuentaFalsa());
    await _escribir(tester, Textos.correo, 'juan@');
    await tester.tap(
      find.textContaining(Textos.terminosDeUso, findRichText: true),
    );
    await tester.pump();
    await _tocarCrear(tester);

    expect(find.text(Textos.errorNombreVacio), findsOneWidget);
    expect(find.text(Textos.errorCorreo), findsOneWidget);
    expect(find.text(Textos.errorContrasenaCorta), findsOneWidget);
  });

  testWidgets('el error del servicio se ve en palabras y no borra lo escrito', (
    tester,
  ) async {
    final cuenta = _CuentaFalsa();
    when(
      () => cuenta.registrar(
        nombre: any(named: 'nombre'),
        telefono: any(named: 'telefono'),
        correo: any(named: 'correo'),
        contrasena: any(named: 'contrasena'),
      ),
    ).thenThrow(const ErrorAcceso('network-request-failed'));

    await _abrir(tester, cuenta);
    await _escribir(tester, Textos.nombreCompleto, 'Juan López');
    await _escribir(tester, Textos.correo, 'juan@correo.com');
    await _escribir(tester, Textos.creeContrasena, 'siembra2026');
    await _escribir(tester, Textos.repetirContrasena, 'siembra2026');
    await tester.ensureVisible(
      find.textContaining(Textos.terminosDeUso, findRichText: true),
    );
    await tester.tap(
      find.textContaining(Textos.terminosDeUso, findRichText: true),
    );
    await tester.pump();
    await _tocarCrear(tester);
    await tester.pump();

    expect(find.text(Textos.errorSinSenal), findsOneWidget);
    expect(find.text('juan@correo.com'), findsOneWidget);
  });

  testWidgets('"Ver" muestra la contraseña', (tester) async {
    await _abrir(tester, _CuentaFalsa());
    await _escribir(tester, Textos.creeContrasena, 'siembra2026');
    EditableText editable() => tester.widget<EditableText>(
      find.descendant(
        of: _campo(Textos.creeContrasena),
        matching: find.byType(EditableText),
      ),
    );
    expect(editable().obscureText, isTrue);
    await tester.tap(find.text(Textos.ver).first);
    await tester.pump();
    expect(editable().obscureText, isFalse);
  });
}

void pruebasFoco() {
  testWidgets('"Siguiente" desde la contraseña pasa a repetirla, no a "Ver"', (
    tester,
  ) async {
    await _abrir(tester, _CuentaFalsa());
    await tester.tap(_campo(Textos.creeContrasena));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    final enfocado = FocusManager.instance.primaryFocus;
    final editableRepetir = tester.state<EditableTextState>(
      find.descendant(
        of: _campo(Textos.repetirContrasena),
        matching: find.byType(EditableText),
      ),
    );
    expect(enfocado, editableRepetir.widget.focusNode);
  });
}
