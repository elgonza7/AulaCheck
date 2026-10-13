import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './Components/models.dart';
import '../utiles/datos.dart';
import 'carreras_page.dart';
import '../utiles/layout_base.dart';

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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: ctrlNombre,
            decoration: const InputDecoration(
                labelText: 'Nombre completo', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrlDni,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'DNI', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrlCarrera,
            decoration: const InputDecoration(
                labelText: 'Carrera', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrlMateria,
            decoration: const InputDecoration(
                labelText: 'Materia', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: guardarDatos,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
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
            child: ListTile(
              leading: const Icon(Icons.school),
              title: Text(p.nombre),
              subtitle: Text('DNI: ${p.dni}\n${p.carrera} - ${p.materia}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: editarDatos,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.book),
            label: const Text('Ver Mis Carreras y Materias'),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
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
