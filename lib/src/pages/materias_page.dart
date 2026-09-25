import 'package:flutter/material.dart';
import './Components/models.dart.dart';
import 'page_class.dart';

class MateriasPage extends StatefulWidget {
  final Materia materia;
  
  const MateriasPage({super.key, required this.materia});

  @override
  State<MateriasPage> createState() => _MateriasPageState();
}

class _MateriasPageState extends State<MateriasPage> {
  late List<Materia> materias;
  final TextEditingController ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    materias = [widget.materia];
  }

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
                if (ctrl.text.isNotEmpty) {
                  setState(() {
                    materias.add(Materia(nombre: ctrl.text));
                  });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Mis materias')),
      backgroundColor: Colors.grey.shade100,
      body: ListView.builder(
        itemCount: materias.length,
        itemBuilder: (context, i) {
          final m = materias[i];
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('Materia: ${m.nombre}'),
              subtitle: const Text('Tocar para ver clases'),
              leading: const Icon(Icons.class_, color: Colors.blue),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PageClass(materia: m),
                  ),
                );
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