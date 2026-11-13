import 'package:flutter/material.dart';

import 'package:aulacheck/src/config/app_theme.dart';
import 'package:aulacheck/src/pages/settings/settings_page.dart';

// Iniciales para el avatar: "María Pérez" -> "MP"
String iniciales(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (partes.isEmpty) return '?';
  return partes.take(2).map((p) => p[0].toUpperCase()).join();
}

PreferredSizeWidget aulaAppBar(
  BuildContext context,
  String titulo, {
  List<Widget> actions = const [],
}) {
  return AppBar(
    title: Text(titulo),
    actions: [
      ...actions,
      IconButton(
        icon: const Icon(Icons.settings_outlined),
        tooltip: 'Abrir ajustes',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
        },
      ),
    ],
  );
}

class LayoutBase extends StatelessWidget {
  final Widget hijo;
  final String titulo;
  final String subtitulo;

  const LayoutBase({
    super.key,
    required this.hijo,
    this.titulo = '',
    this.subtitulo = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: 20),
              // El hueco de la izquierda mide lo mismo que el botón de ajustes
              // de la derecha (48 + 8), así el título queda realmente centrado.
              Row(
                children: [
                  const SizedBox(width: 56),
                  Expanded(
                    child: Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'AULA',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: 'CHECK',
                              style: TextStyle(
                                color: Color(0xFF8A2BE2),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Abrir ajustes',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 40),
              if (titulo.isNotEmpty)
                Text(
                  titulo,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 10),
              if (subtitulo.isNotEmpty)
                Text(
                  subtitulo,
                  style: TextStyle(color: context.textoSuave, fontSize: 14),
                ),
              const SizedBox(height: 40),
              Expanded(child: hijo),
            ],
          ),
        ),
      ),
    );
  }
}
