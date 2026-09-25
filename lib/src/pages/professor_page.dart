import 'package:flutter/material.dart';
import './Components/models.dart.dart';
import 'materias_page.dart';

void qrDialog(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Código QR'),
      content: SelectableText(url),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

class ProfessorPage extends StatefulWidget {
  const ProfessorPage({super.key});

  @override
  State<ProfessorPage> createState() => _ProfessorPageState();
}

class _ProfessorPageState extends State<ProfessorPage> {
  // Simulación de datos para la demo
  final Materia materiaDemo = Materia(nombre: 'Programación Web');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Docente')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => createClassPage(materia: materiaDemo),
                  ),
                );
              },
              child: const Text('Crear Clase Para una Materia'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.book),
              label: const Text('Ver Mis Materias'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MateriasPage(materia: materiaDemo),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class createClassPage extends StatelessWidget {
  final Materia materia;

  const createClassPage({super.key, required this.materia});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Clase')),
      body: Center(
        child: Column(
          children: [
            Text('Aquí puedes crear una clase para la materia: ${materia.nombre}'),
            Expanded(
              child: ListView.builder(
                itemCount: 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(materia.nombre),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Clase Creada'),
                            content: const Text('Se ha creado la clase y se ha generado un QR.'),
                            actions: [
                              TextButton(
                                onPressed: () => qrDialog(
                                  context,
                                  'https://aulacheck.com/clase/${materia.nombre}',
                                ),
                                child: const Text('Ver código QR'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          );
                        },
                      );

                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
           