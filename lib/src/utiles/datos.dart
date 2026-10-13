import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../pages/Components/models.dart';

// Datos compartidos entre pantallas (viven solo mientras la app está abierta).
class Datos {
  static Profesor? profesor;
  static final List<Carrera> carreras = [];

  // Clase que tiene el QR abierto en este momento
  static Clase? claseActiva;

  // Cuánto dura un QR antes de vencer
  static const int minutosValidez = 10;

  static const String claveAsistenciaDispositivo = 'asistencia_dispositivo_';

  // Guarda todas las carreras (con sus materias, clases y asistencias) en el celular.
  // Hay que llamarla cada vez que se cambia algo.
  static Future<void> guardar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = jsonEncode(carreras.map((c) => c.toJson()).toList());
    await prefs.setString('datos_carreras', texto);
  }

  // Lee lo guardado. Se llama una vez al abrir la app (en main.dart).
  static Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString('datos_carreras');
    if (texto == null) return;

    try {
      final lista = jsonDecode(texto) as List;
      carreras
        ..clear()
        ..addAll(lista.map((c) => Carrera.fromJson(c)));
    } catch (_) {
      // Si los datos guardados están dañados, se arranca de cero
    }
  }

  // Cada dispositivo puede registrar una sola asistencia por clase.
  static Future<bool> dispositivoYaRegistro(String claseId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$claveAsistenciaDispositivo$claseId') ?? false;
  }

  static Future<void> guardarAsistenciaDispositivo(String claseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$claveAsistenciaDispositivo$claseId', true);
  }

  // Crea la carrera y la materia si todavía no existen
  static void agregarMateria(String carrera, String materia) {
    var c = carreras.where((c) => c.nombre == carrera).firstOrNull;
    if (c == null) {
      c = Carrera(nombre: carrera);
      carreras.add(c);
    }
    final existe = c.materias.any((m) => m.nombre == materia);
    if (!existe) c.materias.add(Materia(nombre: materia));
    guardar();
  }

  // Texto que se guarda dentro del QR: aulacheck|idClase|momento
  static String generarQr(Clase clase) {
    return 'aulacheck|${clase.id}|${DateTime.now().millisecondsSinceEpoch}';
  }

  // Devuelve la clase si el QR es válido y no venció, o null si no sirve.
  static Clase? validarQr(String codigo) {
    final partes = codigo.split('|');
    if (partes.length != 3 || partes[0] != 'aulacheck') return null;

    final clase = claseActiva;
    if (clase == null || clase.id != partes[1]) return null;

    final momento = int.tryParse(partes[2]);
    if (momento == null) return null;

    final edad = DateTime.now().millisecondsSinceEpoch - momento;
    if (edad > minutosValidez * 60 * 1000) return null;

    return clase;
  }
}
