import 'package:flutter/material.dart';

import 'package:aulacheck/src/config/app_theme.dart';
import 'package:aulacheck/src/config/tema_controller.dart';
import 'package:aulacheck/src/services/datos.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // opciones de los Dropdown
  final List<int> opcionesMinutos = [5, 10, 15, 20];
  final List<int> opcionesRadio = [50, 100, 200, 500];

  Future<void> cerrarSesion() async {
    await Datos.cerrarSesion();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada')),
    );
  }

  Widget titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        texto,
        style: TextStyle(color: context.textoSuave, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profesor = Datos.profesor;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          titulo('Apariencia'),
          Card(
            // se redibuja solo cuando cambia el tema
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

          titulo('QR de asistencia (profesor)'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Duración del QR'),
                  subtitle: const Text('Cuánto tiempo queda activo'),
                  trailing: DropdownButton<int>(
                    value: Datos.minutosQr,
                    underline: const SizedBox(),
                    items: [
                      for (final m in opcionesMinutos)
                        DropdownMenuItem(value: m, child: Text('$m min')),
                    ],
                    onChanged: (valor) {
                      if (valor == null) return;
                      setState(() => Datos.minutosQr = valor);
                      Datos.guardarAjustes();
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: const Text('Distancia máxima'),
                  subtitle: const Text('Qué tan cerca tiene que estar el alumno'),
                  trailing: DropdownButton<int>(
                    value: Datos.radioMetros,
                    underline: const SizedBox(),
                    items: [
                      for (final r in opcionesRadio)
                        DropdownMenuItem(value: r, child: Text('$r m')),
                    ],
                    onChanged: (valor) {
                      if (valor == null) return;
                      setState(() => Datos.radioMetros = valor);
                      Datos.guardarAjustes();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Cuenta: solo si hay un profe logueado
          if (profesor != null) ...[
            titulo('Cuenta'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: Text(profesor.nombre),
                    subtitle: Text(profesor.email),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: cerrarSesion,
                  ),
                ],
              ),
            ),
          ],

          titulo('Acerca de'),
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
