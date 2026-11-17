import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aulacheck/src/models/models.dart';
import 'package:aulacheck/src/services/datos.dart';
import 'package:aulacheck/src/pages/alumno/cruds/datos_alumno.dart';
import 'package:aulacheck/src/pages/alumno/scanner_page.dart';
import 'package:aulacheck/src/config/app_theme.dart';
import 'package:aulacheck/src/widgets/avatar_alumno.dart';
import 'package:aulacheck/src/widgets/layout_base.dart';

class AlumnoPage extends StatefulWidget {
  const AlumnoPage({super.key});

  @override
  State<AlumnoPage> createState() => _AlumnoPageState();
}

class _AlumnoPageState extends State<AlumnoPage> {
  String nombre = "";
  String dni = "";
  String? foto; // foto en base64 (null = no sacó)
  String claseInfo = "";
  String fechaInfo = "";
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  // hoy como texto, para comparar con la última asistencia
  String diaDeHoy() {
    final ahora = DateTime.now();
    return '${ahora.year}-${ahora.month}-${ahora.day}';
  }

  Future<void> cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // el cartel de "asistencia registrada" dura todo el día (antes se borraba)
    final registradoHoy = prefs.getString('ultima_dia') == diaDeHoy();

    setState(() {
      nombre = prefs.getString('nombre') ?? "";
      dni = prefs.getString('dni') ?? "";
      foto = prefs.getString('foto');
      if (registradoHoy) {
        claseInfo = prefs.getString('ultima_materia') ?? "";
        fechaInfo = prefs.getString('ultima_fecha') ?? "";
      }
    });
  }

  // abre el CRUD del alumno (cruds/datos_alumno.dart)
  Future<void> modalInfo() async {
    final cambio = await abrirFormularioAlumno(
      context,
      DatosAlumno(nombre: nombre, dni: dni, foto: foto),
    );
    if (cambio) cargarDatos(); // si guardó algo, releo
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
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      final codigo = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const ScannerPage()),
      );
      if (codigo == null) {
        setState(() => cargando = false);
        return;
      }
      setState(() => cargando = false);

      final ubicacionQr = Datos.ubicacionQr(codigo);
      if (ubicacionQr == null) {
        mostrarError('QR inválido: no contiene una ubicación válida');
        return;
      }

      // Control 1 y 2: que sea el QR activo en la nube y que no haya vencido
      final clase = await Datos.validarQr(codigo);
      if (!mounted) return;
      if (clase == null) {
        mostrarError('QR inválido, vencido o desactivado por el profesor');
        return;
      }

      // Control 3: distancia. El radio lo elige el profe en Ajustes y viene con la clase
      final radio = (clase['radio'] as int? ?? 100).toDouble();
      final dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        ubicacionQr.latitud,
        ubicacionQr.longitud,
      );

      if (dist > radio) {
        mostrarError(
          'Estás demasiado lejos del profesor. '
          'Distancia: ${dist.toInt()} m (máximo ${radio.toInt()} m)',
        );
        return;
      }

      final claseId = clase['id'] as String;
      if (await Datos.dispositivoYaRegistro(claseId)) {
        mostrarError('Este dispositivo ya registró asistencia en esta clase');
        return;
      }

      final dniNumero = int.tryParse(dni) ?? 0;

      // Control de cambio: ¿se registró antes con otro nombre/DNI?
      // Si es así mando también los datos viejos -> aviso naranja al profe.
      final prefs = await SharedPreferences.getInstance();
      final regNombre = prefs.getString('reg_nombre');
      final regDni = int.tryParse(prefs.getString('reg_dni') ?? '');
      final cambio = regDni != null && (regDni != dniNumero || regNombre != nombre);

      final registrado = await Datos.registrarAsistenciaRemota(
        clase,
        Alumno(
          nombre: nombre,
          registro: dniNumero,
          dni: dniNumero,
          nombreAnterior: cambio ? regNombre : null,
          dniAnterior: cambio ? regDni : null,
          foto: foto, // para que el profe vea la cara en la lista
        ),
      );
      if (!mounted) return;
      if (!registrado) {
        mostrarError('Ya registraste tu asistencia en esta clase');
        return;
      }
      await Datos.guardarAsistenciaDispositivo(claseId);

      // Guardo con qué datos se registró (para el próximo control de cambio)
      // y el cartel de registrada, así sigue aunque salga de la pantalla.
      await prefs.setString('reg_nombre', nombre);
      await prefs.setString('reg_dni', dni);
      await prefs.setString('ultima_dia', diaDeHoy());
      await prefs.setString('ultima_materia', clase['materia'] as String);
      await prefs.setString('ultima_fecha', clase['fecha'] as String);

      setState(() {
        claseInfo = clase['materia'] as String;
        fechaInfo = clase['fecha'] as String;
      });

    } catch (e) {
      if (!mounted) return;
      mostrarError('No se pudo registrar la asistencia: $e');
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      AvatarAlumno(nombre: nombre, foto: foto, radio: 26),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'DNI $dni',
                              style: TextStyle(color: context.textoSuave),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Cargar o corregir datos. Corregir NO toma asistencia,
            // solo cambia lo que se manda la próxima vez que escanee.
            ElevatedButton.icon(
              onPressed: modalInfo,
              icon: Icon(
                nombre.isEmpty ? Icons.person_add_alt : Icons.edit_outlined,
              ),
              label: Text(
                nombre.isEmpty ? 'Agregar información' : 'Editar mis datos',
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: nombre.isEmpty || cargando ? null : escanearYValidar,
              icon: cargando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.qr_code_scanner),
              label: Text(
                cargando ? 'Verificando ubicación...' : 'Escanear QR de clase',
              ),
            ),

            if (claseInfo.isNotEmpty) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.exito.withAlpha(30),
                  border: Border.all(color: AppTheme.exito),
                  borderRadius: BorderRadius.circular(AppTheme.radio),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.exito,
                      size: 36,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Asistencia registrada',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppTheme.exito,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Materia: $claseInfo'),
                          Text('Fecha: $fechaInfo'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}