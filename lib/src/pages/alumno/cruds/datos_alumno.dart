import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aulacheck/src/config/app_theme.dart';
import 'package:aulacheck/src/widgets/avatar_alumno.dart';

// CRUD del alumno, guardado en el celu con SharedPreferences:
//   Leer:          DatosAlumno.cargar()
//   Crear/Editar:  FormularioAlumno (nombre, DNI y foto) -> DatosAlumno.guardar()
//   Borrar:        DatosAlumno.borrar()
class DatosAlumno {
  String nombre;
  String dni;
  String? foto; // base64, null si no sacó

  DatosAlumno({required this.nombre, required this.dni, this.foto});

  bool get vacio => nombre.isEmpty;

  static Future<DatosAlumno> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    return DatosAlumno(
      nombre: prefs.getString('nombre') ?? '',
      dni: prefs.getString('dni') ?? '',
      foto: prefs.getString('foto'),
    );
  }

  Future<void> guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nombre);
    await prefs.setString('dni', dni);
    if (foto != null) await prefs.setString('foto', foto!);
  }

  // Borra los datos del alumno del celu.
  // OJO: no borra asistencias ni el candado de una por clase (si no, sería re fácil hacer trampa)
  static Future<void> borrar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nombre');
    await prefs.remove('dni');
    await prefs.remove('foto');
  }
}

// Abre el formulario. true = guardó o borró algo
Future<bool> abrirFormularioAlumno(
  BuildContext context,
  DatosAlumno actual,
) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (_) => FormularioAlumno(actual: actual),
  );
  return resultado ?? false;
}

class FormularioAlumno extends StatefulWidget {
  final DatosAlumno actual;

  const FormularioAlumno({super.key, required this.actual});

  @override
  State<FormularioAlumno> createState() => _FormularioAlumnoState();
}

class _FormularioAlumnoState extends State<FormularioAlumno> {
  late final TextEditingController ctrlNombre =
      TextEditingController(text: widget.actual.nombre);
  late final TextEditingController ctrlDni =
      TextEditingController(text: widget.actual.dni);
  late String? foto = widget.actual.foto;
  String? error;

  bool get editando => !widget.actual.vacio;

  @override
  void dispose() {
    ctrlNombre.dispose();
    ctrlDni.dispose();
    super.dispose();
  }

  // Saca foto (o de galería) y la devuelve en base64.
  // La achico a 300 px para que pese ~20-30 KB y entre en Firestore.
  Future<void> elegirFoto(ImageSource origen) async {
    try {
      final imagen = await ImagePicker().pickImage(
        source: origen,
        preferredCameraDevice: CameraDevice.front, // la de selfie
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 60,
      );
      if (imagen == null) return; // canceló
      final bytes = await imagen.readAsBytes();
      setState(() => foto = base64Encode(bytes));
    } catch (e) {
      setState(() => error = 'No se pudo obtener la foto: $e');
    }
  }

  Future<void> guardar() async {
    final nombre = ctrlNombre.text.trim();
    final dni = ctrlDni.text.trim();

    if (nombre.isEmpty || dni.isEmpty) {
      setState(() => error = 'Completá el nombre y el DNI');
      return;
    }
    // el DNI va como número en la asistencia, así que valido que lo sea
    if (int.tryParse(dni) == null) {
      setState(() => error = 'El DNI tiene que ser un número');
      return;
    }

    await DatosAlumno(nombre: nombre, dni: dni, foto: foto).guardar();
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> borrar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar mis datos'),
        content: const Text(
          'Se borran tu nombre, DNI y foto de este celular. '
          'Tus asistencias ya registradas no se borran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await DatosAlumno.borrar();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(editando ? 'Editar mis datos' : 'Datos del alumno'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarAlumno(
              nombre: ctrlNombre.text.isEmpty ? '?' : ctrlNombre.text,
              foto: foto,
              radio: 40,
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Sacar foto'),
                  onPressed: () => elegirFoto(ImageSource.camera),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galería'),
                  onPressed: () => elegirFoto(ImageSource.gallery),
                ),
              ],
            ),
            TextField(
              controller: ctrlNombre,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrlDni,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'DNI o Registro'),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            if (editando) ...[
              const SizedBox(height: 12),
              Text(
                'Corregir tus datos no registra asistencia. Si ya registraste '
                'hoy con un dato equivocado, pedile al profesor que lo corrija. '
                'En tu próxima asistencia, el profesor va a ver que cambiaste '
                'tus datos.',
                style: TextStyle(fontSize: 12, color: context.textoSuave),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (editando)
          TextButton(
            onPressed: borrar,
            child: const Text('Borrar', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: guardar, child: const Text('Guardar')),
      ],
    );
  }
}
