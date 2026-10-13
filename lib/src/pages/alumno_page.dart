import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import './Components/models.dart';
import '../utiles/datos.dart';
import 'scanner_page.dart';
import '../utiles/layout_base.dart';

class AlumnoPage extends StatefulWidget {
  const AlumnoPage({super.key});

  @override
  State<AlumnoPage> createState() => _AlumnoPageState();
}

class _AlumnoPageState extends State<AlumnoPage> {
  String nombre = "";
  String dni = "";
  String claseInfo = "";
  String fechaInfo = "";
  bool cargando = false;

  final TextEditingController ctrlNombre = TextEditingController();
  final TextEditingController ctrlDni = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombre = prefs.getString('nombre') ?? "";
      dni = prefs.getString('dni') ?? "";
    });
  }

  Future<void> guardarDatos() async {
    final nuevoNombre = ctrlNombre.text.trim();
    final nuevoDni = ctrlDni.text.trim();

    if (nombre.isNotEmpty || dni.isNotEmpty) {
      mostrarError('Este dispositivo ya tiene un alumno cargado');
      return;
    }

    if (nuevoNombre.isEmpty || nuevoDni.isEmpty) {
      mostrarError('Completá el nombre y el DNI');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nuevoNombre);
    await prefs.setString('dni', nuevoDni);
    setState(() {
      nombre = nuevoNombre;
      dni = nuevoDni;
    });
    if (mounted) Navigator.pop(context);
  }

  void modalInfo() {
    if (nombre.isNotEmpty || dni.isNotEmpty) {
      mostrarError('Este dispositivo ya tiene un alumno cargado');
      return;
    }

    ctrlNombre.clear();
    ctrlDni.clear();
    ctrlNombre.text = nombre;
    ctrlDni.text = dni;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Datos del alumno'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrlNombre,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            TextField(
              controller: ctrlDni,
              decoration: const InputDecoration(labelText: 'DNI o Registro'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: guardarDatos,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> escanearYValidar() async {
    setState(() => cargando = true);

    bool serviceEnabled;
    LocationPermission permiso;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      mostrarError('GPS desactivado');
      setState(() => cargando = false);
      return;
    }

    permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        mostrarError('Permisos de ubicacion denegados');
        setState(() => cargando = false);
        return;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      mostrarError('Permisos denegados permanentemente');
      setState(() => cargando = false);
      return;
    }

    try {
      Position pos = await Geolocator.getCurrentPosition();
      
      double latUni = -31.5414;
      double lngUni = -68.5255;
      
      double dist = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, latUni, lngUni
      );

      if (dist > 150) {
        mostrarError('Estas demasiado lejos del aula. Distancia: ${dist.toInt()}m');
        setState(() => cargando = false);
        return;
      }
      
      setState(() => cargando = false);
      if (!mounted) return;

      // Ubicación correcta: ahora se escanea el QR del profesor
      final codigo = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const ScannerPage()),
      );
      if (codigo == null) return;

      final clase = Datos.validarQr(codigo);
      if (clase == null) {
        mostrarError('QR inválido o vencido, escaneá el actual');
        return;
      }

      if (await Datos.dispositivoYaRegistro(clase.id)) {
        mostrarError('Este dispositivo ya registró asistencia en esta clase');
        return;
      }

      final dniNumero = int.tryParse(dni) ?? 0;
      final registrado = clase.registrarAsistencia(
        Alumno(nombre: nombre, registro: dniNumero, dni: dniNumero),
      );
      if (!registrado) {
        mostrarError('Ya registraste tu asistencia en esta clase');
        return;
      }
      Datos.guardar();
      await Datos.guardarAsistenciaDispositivo(clase.id);

      setState(() {
        claseInfo = clase.materia;
        fechaInfo = clase.fecha;
      });

    } catch (e) {
      mostrarError('Error obteniendo ubicacion');
      setState(() => cargando = false);
    }
  }

  void mostrarError(String msj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msj)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: aulaAppBar(context, 'Panel de Alumno'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (nombre.isNotEmpty) ...[
              Text('Alumno: $nombre', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('DNI: $dni', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 20),
            ],
            
            ElevatedButton.icon(
              onPressed: modalInfo,
              icon: const Icon(Icons.person),
              label: Text(
                nombre.isEmpty ? 'Agregar informacion' : 'Alumno configurado',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: nombre.isEmpty || cargando ? null : escanearYValidar,
              icon: cargando 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : const Icon(Icons.qr_code_scanner),
              label: Text(cargando ? 'Verificando ubicacion...' : 'Escanear QR de clase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            if (claseInfo.isNotEmpty) ...[
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Asistencia Registrada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                    const SizedBox(height: 10),
                    Text('Materia: $claseInfo', style: const TextStyle(fontSize: 16)),
                    Text('Fecha: $fechaInfo', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}