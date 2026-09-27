import 'package:agroclima_jalapa/app.dart';
import 'package:agroclima_jalapa/config/textos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la app arranca y muestra la marca', (tester) async {
    await tester.pumpWidget(const AgroClimaApp());
    expect(find.text(Textos.marca), findsOneWidget);
    expect(find.text(Textos.lema), findsOneWidget);
  });
}
