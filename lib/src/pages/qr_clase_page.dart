import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';

import './Components/models.dart';
import '../utiles/datos.dart';
import '../utiles/pdf_helper.dart';
import '../utiles/layout_base.dart';

// Muestra el QR de una clase. Dura 10 minutos y después se puede volver a generar.
class QrClasePage extends StatefulWidget {
  final Materia materia;
  final Clase clase;

  const QrClasePage({super.key, required this.materia, required this.clase});

  @override
  State<QrClasePage> createState() => _QrClasePageState();
}

class _QrClasePageState extends State<QrClasePage> {
  late String qrData;
  late DateTime vence;
  bool ordenAlfabetico = false;
  bool cargandoUbicacion = true;
  String? errorUbicacion;
  Timer? timer;

  bool get vencido => !DateTime.now().isBefore(vence);

  @override
  void initState() {
    super.initState();
    Datos.claseActiva = widget.clase;
    inicializarQr();

    // Cada segundo se actualiza el contador y la lista de presentes
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    Datos.claseActiva = null;
    super.dispose();
  }

  Future<void> inicializarQr() async {
    try {
      final posicion = await obtenerUbicacion();
      if (!mounted) return;
      qrData = Datos.generarQr(
        widget.clase,
        posicion.latitude,
        posicion.longitude,
      );
      vence = DateTime.now().add(const Duration(minutes: Datos.minutosValidez));
      setState(() {
        cargandoUbicacion = false;
        errorUbicacion = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        cargandoUbicacion = false;
        errorUbicacion = e.toString();
      });
    }
  }

  Future<Position> obtenerUbicacion() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Activá el GPS para generar el QR');
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      throw Exception('Se necesita permiso de ubicación');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> generarNuevoQr() async {
    setState(() {
      cargandoUbicacion = true;
      errorUbicacion = null;
    });
    await inicializarQr();
  }

  String tiempoRestante() {
    final resto = vence.difference(DateTime.now());
    final min = resto.inMinutes.toString().padLeft(2, '0');
    final seg = (resto.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$seg';
  }

  // Lista de presentes en el orden elegido
  List<Alumno> alumnosOrdenados() {
    final lista = List<Alumno>.from(widget.clase.alumnos); // orden de llegada
    if (ordenAlfabetico) {
      lista.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );
    }
    return lista;
  }

  Future<void> eliminarAsistencia(Alumno alumno) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar asistencia'),
        content: Text('¿Eliminar la asistencia de ${alumno.nombre}?'),
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
    setState(() => widget.clase.alumnos.remove(alumno));
    await Datos.eliminarAsistenciaDispositivo(widget.clase.id);
    await Datos.guardar();
  }

  Future<void> editarAsistencia(Alumno alumno) async {
    final nombreCtrl = TextEditingController(text: alumno.nombre);
    final dniCtrl = TextEditingController(text: alumno.dni.toString());
    final datos = await showDialog<({String nombre, int dni})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Corregir asistencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            TextField(
              controller: dniCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'DNI o registro'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final nombre = nombreCtrl.text.trim();
              final dni = int.tryParse(dniCtrl.text.trim());
              if (nombre.isNotEmpty && dni != null) {
                Navigator.pop(ctx, (nombre: nombre, dni: dni));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    nombreCtrl.dispose();
    dniCtrl.dispose();
    if (datos == null || !mounted) return;
    setState(() {
      alumno.nombre = datos.nombre;
      alumno.dni = datos.dni;
      alumno.registro = datos.dni;
    });
    await Datos.guardar();
  }

  @override
  Widget build(BuildContext context) {
    final clase = widget.clase;
    final alumnos = alumnosOrdenados();

    return Scaffold(
      appBar: aulaAppBar(
        context,
        '${widget.materia.nombre} - ${clase.fecha}',
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Descargar lista de esta clase',
            onPressed: () => pdfClase(widget.materia, clase, alumnos),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          if (cargandoUbicacion)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorUbicacion != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_off, size: 64, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        errorUbicacion!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: generarNuevoQr,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (vencido) ...[
            const Icon(Icons.timer_off, size: 80, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('El QR venció'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => setState(generarNuevoQr),
              icon: const Icon(Icons.refresh),
              label: const Text('Generar QR nuevo'),
            ),
          ] else ...[
            QrImageView(data: qrData, size: 220, backgroundColor: Colors.white),
            const SizedBox(height: 8),
            Text('Vence en ${tiempoRestante()}'),
          ],
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Presentes: ${alumnos.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Llegada')),
                    ButtonSegment(value: true, label: Text('A-Z')),
                  ],
                  selected: {ordenAlfabetico},
                  onSelectionChanged: (v) =>
                      setState(() => ordenAlfabetico = v.first),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: [
                for (final alumno in alumnos)
                  ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text(alumno.nombre),
                    subtitle: Text('DNI: ${alumno.dni}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (accion) {
                        if (accion == 'editar') editarAsistencia(alumno);
                        if (accion == 'eliminar') eliminarAsistencia(alumno);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'editar', child: Text('Corregir')),
                        PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
