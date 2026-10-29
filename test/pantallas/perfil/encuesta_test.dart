import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/encuesta.dart';
import 'package:agroclima_jalapa/modelos/respuestas_encuesta.dart';
import 'package:agroclima_jalapa/pantallas/perfil/encuesta_pantalla.dart';
import 'package:agroclima_jalapa/pantallas/perfil/encuesta_vm.dart';
import 'package:agroclima_jalapa/servicios/encuesta_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _ServicioFalso extends Mock implements EncuestaServicio {}

void main() {
  late _ServicioFalso servicio;

  setUpAll(() async {
    registerFallbackValue(const RespuestasEncuesta());
    await initializeDateFormatting('es');
  });

  setUp(() {
    servicio = _ServicioFalso();
    when(() => servicio.miEncuesta()).thenAnswer((_) async => null);
    when(() => servicio.enviar(any())).thenAnswer((_) async {});
  });

  Future<void> abrir(WidgetTester tester) async {
    // Alta para que la lista arme todas las preguntas a la vez.
    tester.view.physicalSize = const Size(1080, 2340 * 5);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final enrutador = GoRouter(
      initialLocation: '/perfil/opinion',
      routes: [
        GoRoute(
          path: '/perfil',
          builder: (_, _) => const Scaffold(body: Text('Perfil')),
          routes: [
            GoRoute(
              path: 'opinion',
              builder: (_, _) => ChangeNotifierProvider(
                create: (_) => EncuestaVm(servicio),
                child: const EncuestaPantalla(),
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: TemaApp.claro, routerConfig: enrutador),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, String texto, {int cual = 0}) async {
    final buscador = find.bySemanticsLabel(texto).at(cual);
    await tester.ensureVisible(buscador);
    await tester.pumpAndSettle();
    await tester.tap(buscador);
    await tester.pumpAndSettle();
  }

  bool enviarHabilitado(WidgetTester tester) =>
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text(Textos.enviar),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed !=
      null;

  testWidgets('Enviar se habilita solo con las obligatorias y el permiso', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.text(Textos.preguntaFacil), findsOneWidget);
    expect(enviarHabilitado(tester), isFalse);
    expect(find.text(Textos.faltanRespuestas), findsOneWidget);

    await tocar(tester, 'Fácil');
    await tocar(tester, 'Sí, todo');
    await tocar(tester, 'Mucho');
    // p3 es opcional: se salta. p5 = "Sí" (2.º "Sí" de la pantalla).
    await tocar(tester, Textos.si, cual: 1);
    expect(find.text(Textos.queHizo), findsOneWidget);
    await tocar(tester, 'Todavía no ha habido daño');
    await tocar(tester, 'Tal vez');
    expect(enviarHabilitado(tester), isFalse);

    // El permiso es el último par Sí / No.
    await tocar(tester, Textos.no, cual: 4);
    expect(enviarHabilitado(tester), isTrue);
    expect(find.text(Textos.faltanRespuestas), findsNothing);
  });

  testWidgets('al enviar da las gracias y vuelve a Perfil', (tester) async {
    when(() => servicio.miEncuesta()).thenAnswer(
      (_) async => const Encuesta(
        uid: 'ana',
        versionApp: '1.1.0',
        respuestas: RespuestasEncuesta(
          p1: 'facil',
          p2: 'todo',
          p4: 'mucho',
          p5: 'no',
          p6: 'no',
          p7: 'si',
          consentimiento: true,
        ),
      ),
    );
    await abrir(tester);
    final boton = find.text(Textos.enviar);
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();

    expect(find.text(Textos.graciasOpinion), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    final enviadas =
        verify(() => servicio.enviar(captureAny())).captured.single
            as RespuestasEncuesta;
    expect(enviadas.p1, 'facil');
    expect(enviadas.consentimiento, isTrue);
  });

  testWidgets('si ya respondió, muestra sus respuestas para cambiarlas', (
    tester,
  ) async {
    when(() => servicio.miEncuesta()).thenAnswer(
      (_) async => Encuesta(
        uid: 'ana',
        versionApp: '1.1.0',
        fechaRespuesta: DateTime.utc(2026, 10, 28, 18),
        respuestas: const RespuestasEncuesta(
          p1: 'dificil',
          p3: 'si',
          detalleAviso: 'Lluvia fuerte',
          p8: 'Más cultivos',
        ),
      ),
    );
    await abrir(tester);
    expect(
      find.text(Textos.yaRespondioEncuesta(DateTime.utc(2026, 10, 28, 12))),
      findsOneWidget,
    );
    final dificil = tester.getSemantics(find.bySemanticsLabel('Difícil'));
    expect(dificil, isSemantics(isSelected: true));
    expect(find.text('Lluvia fuerte'), findsOneWidget);
    expect(find.text('Más cultivos'), findsOneWidget);
  });

  testWidgets('si no se pudo enviar, lo dice y se queda', (tester) async {
    when(() => servicio.miEncuesta()).thenAnswer(
      (_) async => const Encuesta(
        uid: 'ana',
        versionApp: '1.1.0',
        respuestas: RespuestasEncuesta(
          p1: 'facil',
          p2: 'todo',
          p4: 'mucho',
          p5: 'no',
          p6: 'no',
          p7: 'si',
          consentimiento: true,
        ),
      ),
    );
    when(() => servicio.enviar(any())).thenThrow(Exception('permiso'));
    await abrir(tester);
    final boton = find.text(Textos.enviar);
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
    expect(find.text(Textos.opinionNoSeEnvio), findsOneWidget);
    expect(find.text(Textos.preguntaFacil), findsOneWidget);
  });
}
