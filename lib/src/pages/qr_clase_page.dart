import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import './Components/models.dart';
import '../utiles/datos.dart';
import '../utiles/pdf_helper.dart';

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
  Timer? timer;

  bool get vencido => !DateTime.now().isBefore(vence);

  @override
  void initState() {
    super.initState();
    Datos.claseActiva = widget.clase;
    generarNuevoQr();

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

  void generarNuevoQr() {
    qrData = Datos.generarQr(widget.clase);
    vence = DateTime.now().add(const Duration(minutes: Datos.minutosValidez));
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
      lista.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final clase = widget.clase;
    final alumnos = alumnosOrdenados();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.materia.nombre} - ${clase.fecha}'),
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
          if (vencido) ...[
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
            QrImageView(
              data: qrData,
              size: 220,
              backgroundColor: Colors.white,
            ),
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  onSelectionChanged: (v) => setState(() => ordenAlfabetico = v.first),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: [
                for (final alumno in alumnos)
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(alumno.nombre),
                    subtitle: Text('DNI: ${alumno.dni}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
