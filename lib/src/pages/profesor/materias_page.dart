import 'package:flutter/material.dart';
import 'package:aulacheck/src/services/datos.dart';
import 'package:aulacheck/src/models/models.dart';
import 'package:aulacheck/src/pages/profesor/page_class.dart';
import 'package:aulacheck/src/widgets/estado_vacio.dart';
import 'package:aulacheck/src/widgets/layout_base.dart';

class MateriasPage extends StatefulWidget {
  final Carrera carrera;

  const MateriasPage({super.key, required this.carrera});

  @override
  State<MateriasPage> createState() => _MateriasPageState();
}

class _MateriasPageState extends State<MateriasPage> {
  final TextEditingController ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void addMateria() {
    ctrl.clear();
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Crear nueva materia'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'Ej: Base de datos 2',
              labelText: 'Nombre de materia',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
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
                    widget.carrera.materias.add(Materia(nombre: ctrl.text.trim()));
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

  void editarMateria(Materia materia) {
    ctrl.text = materia.nombre;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar materia'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre de la materia',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final nombre = ctrl.text.trim();
              if (nombre.isEmpty) return;
              setState(() => materia.nombre = nombre);
              Datos.guardar();
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> eliminarMateria(Materia materia) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar materia'),
        content: Text('¿Eliminar "${materia.nombre}" y todas sus clases?'),
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
    setState(() => widget.carrera.materias.remove(materia));
    await Datos.guardar();
  }

  @override
  Widget build(BuildContext context) {
    final materias = widget.carrera.materias;

    return Scaffold(
      appBar: aulaAppBar(context, widget.carrera.nombre),
      body: materias.isEmpty
          ? const EstadoVacio(
              icono: Icons.menu_book_outlined,
              mensaje: 'Esta carrera todavía no tiene materias.\nTocá "Nueva materia" para agregar una.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: materias.length,
              itemBuilder: (context, i) {
                final m = materias[i];

                return Card(
                  child: ListTile(
                    title: Text(m.nombre),
                    subtitle: Text('${m.clases.length} clases'),
                    leading: const Icon(Icons.menu_book),
                    trailing: PopupMenuButton<String>(
                      onSelected: (accion) {
                        if (accion == 'editar') editarMateria(m);
                        if (accion == 'eliminar') eliminarMateria(m);
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
                          builder: (context) => PageClass(materia: m),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addMateria,
        label: const Text('Nueva materia'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
