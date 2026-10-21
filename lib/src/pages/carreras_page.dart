import 'package:flutter/material.dart';
import '../utiles/datos.dart';
import './Components/models.dart';
import 'materias_page.dart';
import '../utiles/layout_base.dart';

class CarrerasPage extends StatefulWidget {
  const CarrerasPage({super.key});

  @override
  State<CarrerasPage> createState() => _CarrerasPageState();
}

class _CarrerasPageState extends State<CarrerasPage> {
  final TextEditingController ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void addCarrera() {
    ctrl.clear();
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Crear nueva carrera'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ej: Ingeniería en Sistemas',
              labelText: 'Nombre de la carrera',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ctrl.clear();
                Navigator.pop(ctx);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  setState(() {
                    Datos.carreras.add(Carrera(nombre: ctrl.text.trim()));
                  });
                  Datos.guardar();
                  ctrl.clear();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  void editarCarrera(Carrera carrera) {
    ctrl.text = carrera.nombre;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar carrera'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre de la carrera',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final nombre = ctrl.text.trim();
              if (nombre.isEmpty) return;
              setState(() => carrera.nombre = nombre);
              Datos.guardar();
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> eliminarCarrera(Carrera carrera) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar carrera'),
        content: Text('¿Eliminar "${carrera.nombre}" y todas sus materias y clases?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => Datos.carreras.remove(carrera));
    await Datos.guardar();
  }

  @override
  Widget build(BuildContext context) {
    final carreras = Datos.carreras;

    return Scaffold(
      appBar: aulaAppBar(context, 'Mis carreras'),
      body: carreras.isEmpty
          ? const Center(child: Text('Todavía no creaste carreras'))
          : ListView.builder(
              itemCount: carreras.length,
              itemBuilder: (context, i) {
                final c = carreras[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.school, color: Colors.blue),
                    title: Text(c.nombre),
                    subtitle: Text('${c.materias.length} materias'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (accion) {
                        if (accion == 'editar') editarCarrera(c);
                        if (accion == 'eliminar') eliminarCarrera(c);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'editar', child: Text('Editar')),
                        PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MateriasPage(carrera: c),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addCarrera,
        label: const Text('Nueva carrera'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
