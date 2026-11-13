import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aulacheck/src/models/models.dart';
import 'package:aulacheck/src/services/datos.dart';
import 'package:aulacheck/src/pages/profesor/carreras_page.dart';
import 'package:aulacheck/src/config/app_theme.dart';
import 'package:aulacheck/src/widgets/layout_base.dart';

class ProfessorPage extends StatefulWidget {
  const ProfessorPage({super.key});

  @override
  State<ProfessorPage> createState() => _ProfessorPageState();
}

class _ProfessorPageState extends State<ProfessorPage> {
  Profesor? profesor;
  bool cargando = true;

  final TextEditingController ctrlNombre = TextEditingController();
  final TextEditingController ctrlDni = TextEditingController();
  final TextEditingController ctrlCarrera = TextEditingController();
  final TextEditingController ctrlMateria = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    ctrlNombre.dispose();
    ctrlDni.dispose();
    ctrlCarrera.dispose();
    ctrlMateria.dispose();
    super.dispose();
  }

  Future<void> cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('prof_nombre');

    if (nombre != null) {
      profesor = Profesor(
        nombre: nombre,
        dni: prefs.getString('prof_dni') ?? '',
        carrera: prefs.getString('prof_carrera') ?? '',
        materia: prefs.getString('prof_materia') ?? '',
      );
      Datos.profesor = profesor;
      Datos.agregarMateria(profesor!.carrera, profesor!.materia);
    }

    if (mounted) setState(() => cargando = false);
  }

  Future<void> guardarDatos() async {
    if (ctrlNombre.text.trim().isEmpty ||
        ctrlDni.text.trim().isEmpty ||
        ctrlCarrera.text.trim().isEmpty ||
        ctrlMateria.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá todos los campos')),
      );
      return;
    }

    final nuevo = Profesor(
      nombre: ctrlNombre.text.trim(),
      dni: ctrlDni.text.trim(),
      carrera: ctrlCarrera.text.trim(),
      materia: ctrlMateria.text.trim(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prof_nombre', nuevo.nombre);
    await prefs.setString('prof_dni', nuevo.dni);
    await prefs.setString('prof_carrera', nuevo.carrera);
    await prefs.setString('prof_materia', nuevo.materia);

    Datos.profesor = nuevo;
    await Datos.cargar(); // si ese DNI ya tenía datos en la nube, los recupera
    Datos.agregarMateria(nuevo.carrera, nuevo.materia);

    if (mounted) setState(() => profesor = nuevo);
  }

  void editarDatos() {
    ctrlNombre.text = profesor!.nombre;
    ctrlDni.text = profesor!.dni;
    ctrlCarrera.text = profesor!.carrera;
    ctrlMateria.text = profesor!.materia;
    setState(() => profesor = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: aulaAppBar(context, 'Panel Docente'),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : profesor == null
              ? formularioRegistro()
              : panelDocente(),
    );
  }

  Widget formularioRegistro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Datos del profesor',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Los completás una sola vez.',
            style: TextStyle(color: context.textoSuave),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: ctrlNombre,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: ctrlDni,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'DNI',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: ctrlCarrera,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Carrera',
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: ctrlMateria,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Materia',
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: guardarDatos,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget panelDocente() {
    final p = profesor!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.violeta,
                    child: Text(
                      iniciales(p.nombre),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombre,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'DNI ${p.dni}',
                          style: TextStyle(color: context.textoSuave),
                        ),
                        Text(
                          '${p.carrera} · ${p.materia}',
                          style: TextStyle(color: context.textoSuave),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar mis datos',
                    onPressed: editarDatos,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.menu_book),
            label: const Text('Ver Mis Carreras y Materias'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CarrerasPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
