import 'package:flutter/material.dart';
import './Components/models.dart';
import '../utiles/datos.dart';
import '../utiles/pdf_helper.dart';
import 'qr_clase_page.dart';
import '../utiles/layout_base.dart';

class PageClass extends StatefulWidget {
  final Materia materia;

  const PageClass({super.key, required this.materia});

  @override
  State<PageClass> createState() => _PageClassState();
}

class _PageClassState extends State<PageClass> {
  Future<void> editarClase(Clase clase) async {
    final ctrl = TextEditingController(text: clase.nombre);
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar clase'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre de la clase',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (nombre == null || nombre.isEmpty || !mounted) return;
    setState(() => clase.nombre = nombre);
    await Datos.guardar();
  }

  Future<void> eliminarClase(Clase clase) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar clase'),
        content: Text('¿Eliminar "${clase.nombre}" y sus asistencias?'),
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
    setState(() => widget.materia.clases.remove(clase));
    await Datos.guardar();
  }

  Future<void> nuevaClase() async {
    final materia = widget.materia;
    final hoy = Clase(nombre: '', materia: materia.nombre, alumnos: []).fecha;

    // Una sola clase por día: si ya existe, se reabre para generar otro QR
    var clase = materia.clases.where((c) => c.fecha == hoy).firstOrNull;
    if (clase == null) {
      clase = Clase(
        nombre: 'Clase ${materia.clases.length + 1}',
        materia: materia.nombre,
        alumnos: [],
      );
      materia.clases.add(clase);
      Datos.guardar();
      setState(() {});
    }
    await abrirQr(clase);
  }

  Future<void> abrirQr(Clase clase) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrClasePage(materia: widget.materia, clase: clase),
      ),
    );
    // Al volver se actualizan los contadores de presentes
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final clases = widget.materia.clases;

    return Scaffold(
      appBar: aulaAppBar(
        context,
        widget.materia.nombre,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Descargar lista de la materia',
            onPressed: () => pdfMateria(widget.materia),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          resumenAsistencia(),
          const SizedBox(height: 16),
          const Text(
            'Clases',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (clases.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Todavía no hay clases')),
            ),
          for (final clase in clases.reversed)
            Card(
              child: ListTile(
                leading: const Icon(Icons.event, color: Colors.blue),
                title: Text('${clase.nombre} - ${clase.fecha}'),
                subtitle: Text('${clase.alumnos.length} presentes'),
                trailing: PopupMenuButton<String>(
                  onSelected: (accion) {
                    if (accion == 'editar') editarClase(clase);
                    if (accion == 'eliminar') eliminarClase(clase);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                  ],
                ),
                onTap: () => abrirQr(clase),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: nuevaClase,
        label: const Text('Nueva Clase'),
        icon: const Icon(Icons.qr_code),
      ),
    );
  }

  // Muestra los 3 alumnos con más asistencias
  Widget resumenAsistencia() {
    final ranking = widget.materia.rankingAsistencia();
    final totalClases = widget.materia.clases.length;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mayor asistencia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (ranking.isEmpty)
              const Text('Aún no hay asistencias registradas'),
            for (final entrada in ranking.take(3))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.emoji_events, color: Colors.amber),
                title: Text(entrada.key.nombre),
                trailing: Text('${entrada.value}/$totalClases'),
              ),
          ],
        ),
      ),
    );
  }
}
