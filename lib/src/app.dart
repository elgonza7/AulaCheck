import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'package:aulacheck/src/routes/routes.dart';

class AulaCheckApp extends StatelessWidget {
  const AulaCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AulaCheck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.oscuro,
      initialRoute: Rutas.home,
      onGenerateRoute: Rutas.generarRuta,
    );
  }
}
