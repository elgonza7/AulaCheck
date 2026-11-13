import 'package:flutter/material.dart';

import 'package:aulacheck/src/config/tema_controller.dart';

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
            // Se redibuja solo cuando cambia el tema
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: TemaController.modo,
              builder: (context, modo, _) {
                final oscuro = modo == ThemeMode.dark;
                return SwitchListTile(
                  secondary: Icon(
                    oscuro ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  ),
                  title: const Text('Tema oscuro'),
                  subtitle: Text(oscuro ? 'Activado' : 'Tema claro activado'),
                  value: oscuro,
                  onChanged: (valor) => TemaController.cambiar(valor),
                );
              },
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('AulaCheck'),
              subtitle: Text('Control de asistencia con QR y ubicación'),
            ),
          ),
        ],
      ),
    );
  }
}
