import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'config/tema_controller.dart';
import 'routes/routes.dart';

class AulaCheckApp extends StatelessWidget {
  const AulaCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cuando el usuario cambia el tema en Ajustes, este builder se ejecuta de nuevo
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: TemaController.modo,
      builder: (context, modo, _) {
        return MaterialApp(
          title: 'AulaCheck',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro,
          darkTheme: AppTheme.oscuro,
          themeMode: modo,
          initialRoute: Rutas.home,
          onGenerateRoute: Rutas.generarRuta,
        );
      },
    );
  }
}
