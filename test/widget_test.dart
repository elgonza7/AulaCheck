import 'package:flutter_test/flutter_test.dart';

import 'package:aulacheck/src/app.dart';

void main() {
  testWidgets('La pantalla de inicio ofrece elegir profesor o alumno',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AulaCheckApp());

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Soy Profesor'), findsOneWidget);
    expect(find.text('Soy Alumno'), findsOneWidget);
  });
}
