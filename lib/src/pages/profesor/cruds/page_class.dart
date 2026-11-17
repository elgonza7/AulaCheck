import 'package:flutter/material.dart';
import 'package:aulacheck/src/models/models.dart';
import 'package:aulacheck/src/services/datos.dart';
import 'package:aulacheck/src/services/pdf_service.dart';
import 'package:aulacheck/src/pages/profesor/cruds/alumnos_materia_page.dart';
import 'package:aulacheck/src/pages/profesor/qr_clase_page.dart';
import 'package:aulacheck/src/config/app_theme.dart';
import 'package:aulacheck/src/widgets/estado_vacio.dart';
import 'package:aulacheck/src/widgets/layout_base.dart';

class PageClass extends StatefulWidget {
  final Materia materia;

  const PageClass({super.key, required this.materia});

  @override
  State<PageClass> createState() => _PageClassState();
}

class _PageClassState extends State<PageClass> {
  @override
  void initState() {
    super.initState();
    refrescar(); // traigo las asistencias de la nube
  }

  // releo asistencias. También se llama al tirar la lista para abajo
  // (RefreshIndicator).
  Future<void> refrescar() async {
    try {
      await Datos.sincronizarAsistencias();
    } catch (_) {
      // sin internet: dejo lo que ya tenía
    }
    if (mounted) setState(() {});
  }

  // avisos: los que cambiaron datos entre clases
  List<Widget> avisosCambioDatos() {
    final avisos = widget.materia.avisosCambioDatos();
    final distintos = widget.materia.nombresDistintos();
    if (avisos.isEmpty && distintos.isEmpty) return [];

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Avisos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final aviso in avisos)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${aviso.alumno.nombre} (DNI ${aviso.alumno.dni}) se registró '
                    'en ${aviso.clase.nombre} (${aviso.clase.fecha}) con otros datos. '
                    'Antes: ${aviso.alumno.nombreAnterior}, '
                    'DNI ${aviso.alumno.dniAnterior}.',
                    style: TextStyle(color: context.textoSuave),
                  ),
                ),
              // mismo DNI que el padrón, otro nombre
              for (final d in distintos)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'DNI ${d.alumno.dni} se registró como "${d.alumno.nombre}" '
                    'en ${d.clase.nombre} (${d.clase.fecha}), pero en el padrón '
                    'figura como "${d.inscripto.nombre}".',
                    style: TextStyle(color: context.textoSuave),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }

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
    // una clase por día: si ya está la de hoy, abro esa
    var clase = materia.clases.where((c) => c.esDeHoy).firstOrNull;
    final recienCreada = clase == null;
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
    // si ya existía solo la abro, el QR NO se regenera (era el problema de antes)
    await abrirQr(clase, activar: recienCreada);
  }

  Future<void> abrirQr(Clase clase, {bool activar = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrClasePage(
          materia: widget.materia,
          clase: clase,
          activarAlAbrir: activar,
        ),
      ),
    );
    // al volver actualizo cuántos presentes hay
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
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Alumnos de la materia',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlumnosMateriaPage(materia: widget.materia),
                ),
              );
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Descargar lista de la materia',
            onPressed: () => pdfMateria(widget.materia),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refrescar,
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          resumenAsistencia(),
          ...avisosCambioDatos(),
          const SizedBox(height: 8),
          const Text(
            'Clases',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (clases.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: EstadoVacio(
                icono: Icons.event_outlined,
                mensaje: 'Todavía no hay clases.\nTocá "Nueva Clase" para generar el QR de hoy.',
              ),
            ),
          for (final clase in clases.reversed)
            Card(
              child: ListTile(
                leading: const Icon(Icons.event),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: nuevaClase,
        label: const Text('Nueva Clase'),
        icon: const Icon(Icons.qr_code),
      ),
    );
  }

  // top 3 de asistencia
  Widget resumenAsistencia() {
    final ranking = widget.materia.rankingAsistencia();
    final totalClases = widget.materia.clases.length;

    // oro, plata, bronce
    const medallas = [Color(0xFFFFC107), Color(0xFFB0BEC5), Color(0xFFCD7F32)];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, color: AppTheme.violeta),
                SizedBox(width: 8),
                Text(
                  'Mayor asistencia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (ranking.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aún no hay asistencias registradas',
                  style: TextStyle(color: context.textoSuave),
                ),
              ),
            for (final (i, entrada) in ranking.take(3).indexed)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.workspace_premium, color: medallas[i]),
                title: Text(entrada.key.nombre),
                trailing: Text(
                  '${entrada.value}/$totalClases',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
