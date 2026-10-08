import 'package:flutter/material.dart';
import './Components/models.dart';
import '../utiles/datos.dart';
import '../utiles/pdf_helper.dart';
import 'qr_clase_page.dart';

class PageClass extends StatefulWidget {
  final Materia materia;

  const PageClass({super.key, required this.materia});

  @override
  State<PageClass> createState() => _PageClassState();
}

class _PageClassState extends State<PageClass> {
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
      appBar: AppBar(
        title: Text(widget.materia.nombre),
        centerTitle: true,
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
                trailing: const Icon(Icons.qr_code),
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
