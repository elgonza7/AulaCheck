import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aulacheck/src/app.dart';
import 'package:aulacheck/src/config/tema_controller.dart';

void main() {
  testWidgets('La pantalla de inicio ofrece elegir profesor o alumno',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AulaCheckApp());

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Soy Profesor'), findsOneWidget);
    expect(find.text('Soy Alumno'), findsOneWidget);
  });

  testWidgets('Al cambiar al tema claro la app se sigue mostrando bien',
      (WidgetTester tester) async {
    TemaController.modo.value = ThemeMode.light;
    await tester.pumpWidget(const AulaCheckApp());
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(find.text('Bienvenido'), findsOneWidget);

    TemaController.modo.value = ThemeMode.dark; // se deja como estaba
  });
}
