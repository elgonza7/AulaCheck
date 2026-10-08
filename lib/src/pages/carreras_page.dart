import 'package:flutter/material.dart';
import '../utiles/datos.dart';
import './Components/models.dart';
import 'materias_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final carreras = Datos.carreras;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis carreras')),
      backgroundColor: Colors.grey.shade100,
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
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
