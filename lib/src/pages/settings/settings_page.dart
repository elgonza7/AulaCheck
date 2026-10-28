import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('AulaCheck'),
              subtitle: const Text('Configuración de la aplicación'),
            ),
          ),
        ],
      ),
    );
  }
}
