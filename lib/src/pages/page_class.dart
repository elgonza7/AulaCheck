import 'package:flutter/material.dart';
import './Components/models.dart.dart';

class PageClass extends StatefulWidget {
  final Materia materia;
  
  const PageClass({super.key, required this.materia}); 

  @override
  State<PageClass> createState() => _PageClassState();
}

class _PageClassState extends State<PageClass> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.materia.nombre),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Aquí irá la lista de clases de ${widget.materia.nombre}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Lógica para crear nueva clase y abrir QR
        },
        label: const Text('Nueva Clase'),
        icon: const Icon(Icons.qr_code),
      ),
    );
  }
}