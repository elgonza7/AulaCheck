import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AlumnoPage extends StatefulWidget {
  const AlumnoPage({super.key});
  final double codeClass = 0.0; // Variable para almacenar el valor del código de clase
  @override
  State<AlumnoPage> createState() => _AlumnoPageState();
}

class _AlumnoPageState extends State<AlumnoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumno'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Center(
        child: QrImageView(
          
          data: 'https://aulacheck.com/alumno', // Aquí puedes poner la información que quieras codificar en el QR
          version: QrVersions.auto,
          size: 200.0,
        ),
      ),
    );
  }
}