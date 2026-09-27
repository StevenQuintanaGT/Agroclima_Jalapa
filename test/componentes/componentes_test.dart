import 'package:agroclima_jalapa/componentes/aviso_apoyo.dart';
import 'package:agroclima_jalapa/componentes/aviso_no_vigente.dart';
import 'package:agroclima_jalapa/componentes/boton_principal.dart';
import 'package:agroclima_jalapa/componentes/boton_secundario.dart';
import 'package:agroclima_jalapa/componentes/chip_semaforo.dart';
import 'package:agroclima_jalapa/componentes/estado_error.dart';
import 'package:agroclima_jalapa/componentes/marca_dato_guardado.dart';
import 'package:agroclima_jalapa/config/tema/tema_app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(Widget hijo, {ThemeData? tema}) => MaterialApp(
  theme: tema ?? TemaApp.claro,
  home: Scaffold(body: hijo),
);

void main() {
  group('ChipSemaforo', () {
    for (final nivel in NivelSeveridad.values) {
      testWidgets('${nivel.valor}: palabra + ícono', (tester) async {
        await tester.pumpWidget(_envolver(ChipSemaforo(nivel: nivel)));
        expect(find.text(Textos.palabraNivel(nivel)), findsOneWidget);
        expect(find.byIcon(ChipSemaforo.iconoDe(nivel)), findsOneWidget);
      });
    }

    testWidgets('en tema oscuro usa el ámbar aclarado', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const ChipSemaforo(nivel: NivelSeveridad.preventiva),
          tema: TemaApp.oscuro,
        ),
      );
      final texto = tester.widget<Text>(find.text('PRECAUCIÓN'));
      expect(texto.style?.color, const Color(0xFFF6C453));
    });
  });

  group('BotonPrincipal', () {
    testWidgets('mide al menos 60 dp y responde', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        _envolver(BotonPrincipal(texto: 'Entrar', alPresionar: () => toques++)),
      );
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(60),
      );
      await tester.tap(find.text('Entrar'));
      expect(toques, 1);
    });

    testWidgets('cargando muestra el texto de espera y no responde', (
      tester,
    ) async {
      var toques = 0;
      await tester.pumpWidget(
        _envolver(
          BotonPrincipal(
            texto: Textos.entrar,
            textoCargando: Textos.entrando,
            cargando: true,
            alPresionar: () => toques++,
          ),
        ),
      );
      expect(find.text(Textos.entrando), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text(Textos.entrando));
      expect(toques, 0);
    });
  });

  testWidgets('BotonSecundario mide al menos 56 dp', (tester) async {
    await tester.pumpWidget(
      _envolver(BotonSecundario(texto: Textos.ahoraNo, alPresionar: () {})),
    );
    expect(
      tester.getSize(find.byType(OutlinedButton)).height,
      greaterThanOrEqualTo(56),
    );
  });

  group('EstadoError', () {
    testWidgets('sin datos guardados solo ofrece reintentar', (tester) async {
      var reintentos = 0;
      await tester.pumpWidget(
        _envolver(EstadoError(alReintentar: () => reintentos++)),
      );
      expect(find.text(Textos.errorServicioTitulo), findsOneWidget);
      expect(find.text(Textos.verDatosGuardados), findsNothing);
      await tester.tap(find.text(Textos.intentarDeNuevo));
      expect(reintentos, 1);
    });

    testWidgets('con datos guardados ofrece verlos', (tester) async {
      var vistos = 0;
      await tester.pumpWidget(
        _envolver(
          EstadoError(alReintentar: () {}, alVerGuardados: () => vistos++),
        ),
      );
      await tester.tap(find.text(Textos.verDatosGuardados));
      expect(vistos, 1);
    });
  });

  testWidgets('sin conexión: banner y fecha del dato guardado', (tester) async {
    await tester.pumpWidget(
      _envolver(
        const Column(
          children: [
            AvisoNoVigente(),
            MarcaDatoGuardado(fechaHora: '12 de agosto, 6:00 a.m.'),
          ],
        ),
      ),
    );
    expect(find.text(Textos.sinInternetTitulo), findsOneWidget);
    expect(find.text('Datos del 12 de agosto, 6:00 a.m.'), findsOneWidget);
  });

  testWidgets('AvisoApoyo dice que no es aviso oficial', (tester) async {
    await tester.pumpWidget(_envolver(const AvisoApoyo()));
    expect(find.textContaining('INSIVUMEH'), findsOneWidget);
  });
}
