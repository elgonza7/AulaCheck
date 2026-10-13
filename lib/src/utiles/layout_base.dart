import 'package:flutter/material.dart';

import '../pages/settings_page.dart';

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
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Expanded(
                    flex: 2,
                    child: Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'AULA',
                              style: TextStyle(
                                color: Colors.white,
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
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                    ),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 10),
              if (subtitulo.isNotEmpty)
                Text(
                  subtitulo,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
