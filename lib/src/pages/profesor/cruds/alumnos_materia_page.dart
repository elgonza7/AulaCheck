import 'package:flutter/material.dart';

import 'package:aulacheck/src/config/app_theme.dart';
import 'package:aulacheck/src/models/models.dart';
import 'package:aulacheck/src/services/datos.dart';
import 'package:aulacheck/src/widgets/avatar_alumno.dart';
import 'package:aulacheck/src/widgets/estado_vacio.dart';
import 'package:aulacheck/src/widgets/layout_base.dart';

// Padrón de la materia (CRUD):
//   - Crear: agregar un alumno con nombre y DNI
//   - Leer: lista con el porcentaje de asistencia de cada uno
//   - Editar: corregir nombre o DNI
//   - Borrar: sacarlo del padrón
// También marca si alguien se registró con otros datos.
// Se guarda junto con la materia con Datos.guardar().
class AlumnosMateriaPage extends StatefulWidget {
  final Materia materia;

  const AlumnosMateriaPage({super.key, required this.materia});

  @override
  State<AlumnosMateriaPage> createState() => _AlumnosMateriaPageState();
}

class _AlumnosMateriaPageState extends State<AlumnosMateriaPage> {
  Materia get materia => widget.materia;

  void mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // mismo form para crear y editar. null = canceló
  Future<({String nombre, int dni})?> formulario({
    required String titulo,
    String nombre = '',
    String dni = '',
  }) async {
    final ctrlNombre = TextEditingController(text: nombre);
    final ctrlDni = TextEditingController(text: dni);

    final datos = await showDialog<({String nombre, int dni})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrlNombre,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrlDni,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'DNI'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final n = ctrlNombre.text.trim();
              final d = int.tryParse(ctrlDni.text.trim());
              if (n.isEmpty || d == null) return; // si falta algo no cierra
              Navigator.pop(ctx, (nombre: n, dni: d));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctrlNombre.dispose();
    ctrlDni.dispose();
    return datos;
  }

  // CREAR
  Future<void> agregar({String nombre = '', String dni = ''}) async {
    final datos = await formulario(
      titulo: 'Agregar alumno',
      nombre: nombre,
      dni: dni,
    );
    if (datos == null || !mounted) return;

    if (materia.inscriptoPorDni(datos.dni) != null) {
      mostrarMensaje('Ya hay un alumno con ese DNI en el padrón');
      return;
    }
    setState(() {
      materia.inscriptos.add(Inscripto(nombre: datos.nombre, dni: datos.dni));
    });
    await Datos.guardar();
  }

  // EDITAR
  Future<void> editar(Inscripto ins) async {
    final datos = await formulario(
      titulo: 'Editar alumno',
      nombre: ins.nombre,
      dni: ins.dni.toString(),
    );
    if (datos == null || !mounted) return;

    final otro = materia.inscriptoPorDni(datos.dni);
    if (otro != null && otro != ins) {
      mostrarMensaje('Ya hay otro alumno con ese DNI');
      return;
    }
    setState(() {
      ins.nombre = datos.nombre;
      ins.dni = datos.dni;
    });
    await Datos.guardar();
  }

  // BORRAR
  Future<void> eliminar(Inscripto ins) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar del padrón'),
        content: Text(
          '¿Quitar a ${ins.nombre}? Sus asistencias ya registradas no se borran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => materia.inscriptos.remove(ins));
    await Datos.guardar();
  }

  // foto: agarro la de su última asistencia que tenga
  String? fotoDe(int dni) {
    for (final clase in materia.clases.reversed) {
      for (final a in clase.alumnos) {
        if (a.dni == dni && a.foto != null) return a.foto;
      }
    }
    return null;
  }

  // avisos de un alumno: si alguna vez puso otro nombre
  // o si cambió sus datos desde la app.
  List<String> avisosDe(Inscripto ins) {
    final avisos = <String>[];
    for (final clase in materia.clases) {
      for (final a in clase.alumnos.where((a) => a.dni == ins.dni)) {
        if (a.nombre.trim().toLowerCase() != ins.nombre.trim().toLowerCase()) {
          avisos.add('Se registró como "${a.nombre}" el ${clase.fecha}');
        }
        if (a.cambioDatos) {
          avisos.add(
            'Cambió sus datos el ${clase.fecha} '
            '(antes: ${a.nombreAnterior}, DNI ${a.dniAnterior})',
          );
        }
      }
    }
    return avisos;
  }

  @override
  Widget build(BuildContext context) {
    final total = materia.clases.length;
    final inscriptos = List<Inscripto>.from(materia.inscriptos)
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    final sinInscribir = materia.registradosSinInscribir();

    return Scaffold(
      appBar: aulaAppBar(context, 'Alumnos · ${materia.nombre}'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Text(
            '${inscriptos.length} inscriptos · $total clases dictadas',
            style: TextStyle(color: context.textoSuave),
          ),
          const SizedBox(height: 12),
          if (inscriptos.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: EstadoVacio(
                icono: Icons.groups_outlined,
                mensaje: 'Todavía no cargaste alumnos.\n'
                    'Tocá "Agregar alumno" para armar el padrón.',
              ),
            ),
          for (final ins in inscriptos) tarjetaInscripto(ins, total),

          // escanearon pero no están en el padrón (botón para agregarlos)
          if (sinInscribir.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.person_search, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Registrados sin estar en el padrón',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final a in sinInscribir)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.help_outline, color: Colors.orange),
                  title: Text(a.nombre),
                  subtitle: Text('DNI ${a.dni}'),
                  trailing: TextButton(
                    onPressed: () =>
                        agregar(nombre: a.nombre, dni: a.dni.toString()),
                    child: const Text('Agregar'),
                  ),
                ),
              ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => agregar(),
        label: const Text('Agregar alumno'),
        icon: const Icon(Icons.person_add_alt),
      ),
    );
  }

  Widget tarjetaInscripto(Inscripto ins, int total) {
    final fue = materia.asistenciasDe(ins.dni);
    final porcentaje = total == 0 ? 0 : (fue * 100 / total).round();
    final avisos = avisosDe(ins);
    // verde >= 75%, naranja 50-74%, rojo < 50%
    final color = porcentaje >= 75
        ? AppTheme.exito
        : porcentaje >= 50
            ? Colors.orange
            : Colors.red;

    return Card(
      child: ListTile(
        leading: AvatarAlumno(nombre: ins.nombre, foto: fotoDe(ins.dni)),
        title: Text(ins.nombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DNI ${ins.dni} · fue a $fue de $total clases'),
            for (final aviso in avisos)
              Text(
                '⚠ $aviso',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$porcentaje%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            PopupMenuButton<String>(
              onSelected: (accion) {
                if (accion == 'editar') editar(ins);
                if (accion == 'eliminar') eliminar(ins);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'eliminar', child: Text('Quitar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
