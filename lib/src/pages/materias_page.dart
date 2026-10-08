import 'package:flutter/material.dart';
import '../utiles/datos.dart';
import './Components/models.dart';
import 'page_class.dart';

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

  @override
  Widget build(BuildContext context) {
    final materias = widget.carrera.materias;

    return Scaffold(
      appBar: AppBar(title: Text(widget.carrera.nombre)),
      backgroundColor: Colors.grey.shade100,
      body: materias.isEmpty
          ? const Center(child: Text('Todavía no creaste materias'))
          : ListView.builder(
              itemCount: materias.length,
              itemBuilder: (context, i) {
                final m = materias[i];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(m.nombre),
                    subtitle: Text('${m.clases.length} clases'),
                    leading: const Icon(Icons.class_, color: Colors.blue),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
