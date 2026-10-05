import 'package:agroclima_jalapa/pantallas/alertas/apertura_alertas.dart';
import 'package:agroclima_jalapa/servicios/notificaciones_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  group('canales (mismos ids que el ciclo)', () {
    test('uno por nivel; PELIGRO con importancia alta', () {
      final canales = NotificacionesServicio.canales.values;
      expect(canales.map((c) => c.id), [
        'alertas_peligro',
        'alertas_precaucion',
        'alertas_normal',
      ]);
      expect(canales.first.importance, Importance.high);
    });

    test('el canal sale del nivel del aviso; sin nivel, NORMAL', () {
      expect(
        NotificacionesServicio.canalDe({'nivel': 'critica'}).id,
        'alertas_peligro',
      );
      expect(
        NotificacionesServicio.canalDe({'nivel': 'preventiva'}).id,
        'alertas_precaucion',
      );
      expect(NotificacionesServicio.canalDe({}).id, 'alertas_normal');
    });
  });

  test('alertaId de los datos del aviso', () {
    expect(NotificacionesServicio.alertaDe({'alertaId': 'a1'}), 'a1');
    expect(NotificacionesServicio.alertaDe({'alertaId': ''}), isNull);
    expect(NotificacionesServicio.alertaDe({}), isNull);
  });

  group('apertura al tocar un aviso', () {
    test('con alguien escuchando, abre en el momento', () {
      final servicio = NotificacionesServicio();
      final abiertas = <String>[];
      servicio.alAbrirAlerta(abiertas.add);
      servicio.abrir('a1');
      servicio.abrir(null);
      expect(abiertas, ['a1']);
    });

    test('tocado al arrancar: espera y se entrega una sola vez', () {
      final servicio = NotificacionesServicio()..abrir('a2');
      final abiertas = <String>[];
      servicio.alAbrirAlerta(abiertas.add);
      servicio.alAbrirAlerta(null);
      servicio.alAbrirAlerta(abiertas.add);
      expect(abiertas, ['a2']);
    });
  });

  testWidgets('la barra inferior abre el detalle de la alerta pendiente', (
    tester,
  ) async {
    final servicio = NotificacionesServicio()..abrir('a3');
    final enrutador = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const AperturaAlertas(child: Text('Inicio')),
        ),
        GoRoute(
          path: '/alertas/:alertaId',
          builder: (_, estado) =>
              Text('Alerta ${estado.pathParameters['alertaId']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      Provider.value(
        value: servicio,
        child: MaterialApp.router(routerConfig: enrutador),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alerta a3'), findsOneWidget);

    // "Atrás" vuelve a Inicio.
    enrutador.pop();
    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsOneWidget);
  });
}
