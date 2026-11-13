import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aulacheck/src/models/models.dart';
import 'package:aulacheck/src/services/datos.dart';
import 'package:aulacheck/src/pages/alumno/scanner_page.dart';
import 'package:aulacheck/src/config/app_theme.dart';
import 'package:aulacheck/src/widgets/layout_base.dart';

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

  // Fecha de hoy como texto, para saber si la última asistencia fue hoy
  String diaDeHoy() {
    final ahora = DateTime.now();
    return '${ahora.year}-${ahora.month}-${ahora.day}';
  }

  Future<void> cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // El aviso de "asistencia registrada" se muestra durante todo el día
    final registradoHoy = prefs.getString('ultima_dia') == diaDeHoy();

    setState(() {
      nombre = prefs.getString('nombre') ?? "";
      dni = prefs.getString('dni') ?? "";
      if (registradoHoy) {
        claseInfo = prefs.getString('ultima_materia') ?? "";
        fechaInfo = prefs.getString('ultima_fecha') ?? "";
      }
    });
  }

  Future<void> guardarDatos() async {
    final nuevoNombre = ctrlNombre.text.trim();
    final nuevoDni = ctrlDni.text.trim();

    if (nuevoNombre.isEmpty || nuevoDni.isEmpty) {
      mostrarError('Completá el nombre y el DNI');
      return;
    }

    // El DNI se guarda como número en la asistencia, así que tiene que serlo
    if (int.tryParse(nuevoDni) == null) {
      mostrarError('El DNI tiene que ser un número');
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
    // Si ya hay datos cargados se muestran para poder corregirlos
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
            if (nombre.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Corregir tus datos no registra asistencia. Si ya registraste '
                'hoy con un dato equivocado, pedile al profesor que lo corrija. '
                'En tu próxima asistencia, el profesor va a ver que cambiaste '
                'tus datos.',
                style: TextStyle(fontSize: 12, color: ctx.textoSuave),
              ),
            ],
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

      final dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        ubicacionQr.latitud,
        ubicacionQr.longitud,
      );

      if (dist > Datos.radioAsistenciaMetros) {
        mostrarError(
          'Estás demasiado lejos del profesor. '
          'Distancia: ${dist.toInt()} m '
          '(máximo ${Datos.radioAsistenciaMetros.toInt()} m)',
        );
        return;
      }

      // El QR se valida contra la nube: tiene que ser el vigente del profesor
      final clase = await Datos.validarQr(codigo);
      if (!mounted) return;
      if (clase == null) {
        mostrarError('QR inválido o vencido, escaneá el actual');
        return;
      }

      final claseId = clase['id'] as String;
      if (await Datos.dispositivoYaRegistro(claseId)) {
        mostrarError('Este dispositivo ya registró asistencia en esta clase');
        return;
      }

      final dniNumero = int.tryParse(dni) ?? 0;

      // ¿Cambió sus datos desde la última asistencia que registró?
      // Si es así, se guardan los datos anteriores para avisarle al profesor.
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
        ),
      );
      if (!mounted) return;
      if (!registrado) {
        mostrarError('Ya registraste tu asistencia en esta clase');
        return;
      }
      await Datos.guardarAsistenciaDispositivo(claseId);

      // Se recuerdan los datos con los que se registró y el aviso de "asistencia
      // registrada", para que siga apareciendo aunque se salga de la pantalla.
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
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.violeta,
                        child: Text(
                          iniciales(nombre),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

            // Se puede cargar y también corregir. Corregir NO registra asistencia:
            // solo cambia los datos que se van a usar la próxima vez que escanees.
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