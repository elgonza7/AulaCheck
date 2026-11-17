import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:aulacheck/src/models/models.dart';
import 'package:aulacheck/src/services/datos.dart';
import 'package:aulacheck/src/services/pdf_service.dart';
import 'package:aulacheck/src/config/app_theme.dart';
import 'package:aulacheck/src/widgets/estado_vacio.dart';
import 'package:aulacheck/src/widgets/avatar_alumno.dart';
import 'package:aulacheck/src/widgets/layout_base.dart';

// Pantalla de una clase (un día). El QR NO se genera solo al entrar,
// se activa/desactiva con el botón de arriba (al lado del PDF).
// Vence solo con los minutos de Ajustes, y solo se activa el día de la clase.
class QrClasePage extends StatefulWidget {
  final Materia materia;
  final Clase clase;
  final bool activarAlAbrir; // true si la acabo de crear

  const QrClasePage({
    super.key,
    required this.materia,
    required this.clase,
    this.activarAlAbrir = false,
  });

  @override
  State<QrClasePage> createState() => _QrClasePageState();
}

class _QrClasePageState extends State<QrClasePage> {
  String? qrData; // null = no hay QR activo
  DateTime? vence;
  bool ordenAlfabetico = false;
  bool cargando = true; // esperando la nube o el GPS
  Timer? timer;
  StreamSubscription<List<Alumno>>? suscripcionAsistencias;

  // activo = existe y no venció
  bool get activo =>
      qrData != null && vence != null && DateTime.now().isBefore(vence!);

  @override
  void initState() {
    super.initState();
    cargarQrActivo();

    // Stream: me avisa cada vez que alguien registra (no es Future, avisa muchas veces)
    suscripcionAsistencias =
        Datos.escucharAsistencias(widget.clase.id).listen((presentes) {
      if (!mounted) return;
      setState(() => widget.clase.alumnos = presentes);
    });

    // Timer cada 1 seg: actualiza el contador (y la lista)
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    suscripcionAsistencias?.cancel();
    super.dispose();
  }

  void mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // al entrar: si ya había QR activo (ej: cerré la app y volví) muestro ese
  // con el tiempo que le queda. Si no, queda desactivado.
  Future<void> cargarQrActivo() async {
    try {
      final existente = await Datos.qrActivo(widget.clase.id);
      if (!mounted) return;
      qrData = existente?.qr;
      vence = existente?.vence;
    } catch (_) {
      // sin internet: lo muestro desactivado
    }
    if (!mounted) return;
    setState(() => cargando = false);

    // clase nueva: se activa sola la primera vez
    if (widget.activarAlAbrir && !activo) activarQr();
  }

  // QR nuevo con mi GPS y lo subo a la nube (el viejo deja de servir)
  Future<void> activarQr() async {
    if (!widget.clase.esDeHoy) {
      mostrarMensaje('Solo se puede activar el QR el día de la clase');
      return;
    }
    setState(() => cargando = true);
    try {
      final posicion = await obtenerUbicacion();
      final nuevo = Datos.generarQr(
        widget.clase,
        posicion.latitude,
        posicion.longitude,
      );
      await Datos.publicarQr(widget.clase, nuevo);
      qrData = nuevo;
      vence = DateTime.now().add(Duration(minutes: Datos.minutosQr));
    } catch (e) {
      if (mounted) mostrarMensaje('No se pudo activar el QR: $e');
    }
    if (mounted) setState(() => cargando = false);
  }

  // borro el QR de la nube: ya nadie más se puede registrar
  Future<void> desactivarQr() async {
    setState(() => cargando = true);
    try {
      await Datos.desactivarQr(widget.clase.id);
      qrData = null;
      vence = null;
    } catch (e) {
      if (mounted) mostrarMensaje('No se pudo desactivar el QR: $e');
    }
    if (mounted) setState(() => cargando = false);
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

  // aviso si no está en el padrón o está con otro nombre
  List<Widget> avisoPadron(Alumno alumno) {
    const estilo = TextStyle(color: Colors.orange, fontSize: 12);
    final ins = widget.materia.inscriptoPorDni(alumno.dni);
    if (ins == null) {
      return [const Text('⚠ No está en el padrón de la materia', style: estilo)];
    }
    if (ins.nombre.trim().toLowerCase() != alumno.nombre.trim().toLowerCase()) {
      return [Text('⚠ En el padrón figura como "${ins.nombre}"', style: estilo)];
    }
    return [];
  }

  String tiempoRestante() {
    final resto = vence!.difference(DateTime.now());
    final min = resto.inMinutes.toString().padLeft(2, '0');
    final seg = (resto.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$seg';
  }

  // presentes en el orden que elegí
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
    await Datos.eliminarAsistenciaRemota(widget.clase.id, alumno.dni);
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
    final dniAnterior = alumno.dni;
    setState(() {
      alumno.nombre = datos.nombre;
      alumno.dni = datos.dni;
      alumno.registro = datos.dni;
    });
    await Datos.actualizarAsistenciaRemota(widget.clase.id, dniAnterior, alumno);
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
          // botón Activar / Desactivar (al lado del PDF)
          if (!cargando)
            activo
                ? TextButton.icon(
                    onPressed: desactivarQr,
                    icon: const Icon(Icons.qr_code_2, color: Colors.red),
                    label: const Text(
                      'Desactivar',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                : TextButton.icon(
                    // clase de otro día: no se puede activar
                    onPressed: clase.esDeHoy ? activarQr : null,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Activar'),
                  ),
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
          if (cargando)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (!activo) ...[
            Icon(Icons.qr_code_2, size: 80, color: context.textoSuave),
            const SizedBox(height: 8),
            const Text(
              'QR desactivado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                clase.esDeHoy
                    ? 'Tocá "Activar" para mostrar el QR durante '
                        '${Datos.minutosQr} minutos.'
                    : 'Esta clase ya pasó: el QR solo se puede activar el día de la clase.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textoSuave),
              ),
            ),
          ] else ...[
            // marco blanco para que el QR se lea bien en tema oscuro
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radio),
              ),
              child: QrImageView(
                data: qrData!,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 18, color: context.textoSuave),
                const SizedBox(width: 6),
                Text(
                  'Vence en ${tiempoRestante()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
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
                if (alumnos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: EstadoVacio(
                      icono: Icons.how_to_reg_outlined,
                      mensaje: 'Todavía no se registró nadie.\nLos alumnos aparecen acá en cuanto escanean.',
                    ),
                  ),
                for (final alumno in alumnos)
                  ListTile(
                    leading: AvatarAlumno(
                      nombre: alumno.nombre,
                      foto: alumno.foto,
                    ),
                    title: Text(alumno.nombre),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DNI: ${alumno.dni}'),
                        // comparo con el padrón (si cargué uno)
                        if (widget.materia.inscriptos.isNotEmpty)
                          ...avisoPadron(alumno),
                        // aviso naranja: cambió sus datos
                        if (alumno.cambioDatos)
                          Text(
                            '⚠ Cambió sus datos (antes: ${alumno.nombreAnterior}, '
                            'DNI ${alumno.dniAnterior})',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
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
