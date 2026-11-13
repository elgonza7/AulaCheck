import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aulacheck/src/models/models.dart';

// Datos compartidos entre pantallas.
// Se guardan en Firestore (la nube), así el profesor y los alumnos pueden
// usar celulares distintos.
//
// Colecciones de Firestore:
//   profesores/{dni}          -> árbol completo de carreras, materias y clases del profesor
//   clases/{idClase}          -> QR vigente de la clase (lo escribe el profesor, lo lee el alumno)
//   asistencias/{idClase}_{dni} -> un documento por alumno presente
class Datos {
  static Profesor? profesor;
  static final List<Carrera> carreras = [];

  // Cuánto dura un QR antes de vencer
  static const int minutosValidez = 10;
  static const double radioAsistenciaMetros = 100;

  static const String claveAsistenciaDispositivo = 'asistencia_dispositivo_';

  // Evita pisar lo guardado en la nube con una lista vacía si todavía no se pudo leer
  static bool _cargado = false;

  static const Duration _espera = Duration(seconds: 8);

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // DNI del profesor: se usa como nombre del documento donde se guardan sus datos
  static Future<String?> _dniProfesor() async {
    var dni = profesor?.dni;
    if (dni == null || dni.trim().isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      dni = prefs.getString('prof_dni');
    }
    if (dni == null || dni.trim().isEmpty) return null;
    return dni.trim().replaceAll('/', '_');
  }

  // Guarda todas las carreras (con sus materias, clases y asistencias) en la nube.
  // Hay que llamarla cada vez que se cambia algo.
  static Future<void> guardar() async {
    final dni = await _dniProfesor();
    if (dni == null) return;
    if (!_cargado) {
      debugPrint('No se guardó: todavía no se pudo leer lo que había en la nube');
      return;
    }

    try {
      final texto = jsonEncode(carreras.map((c) => c.toJson()).toList());
      await _db
          .collection('profesores')
          .doc(dni)
          .set({'datos': texto}).timeout(_espera);
    } catch (e) {
      debugPrint('Error al guardar en Firestore: $e');
    }
  }

  // Lee lo guardado en la nube. Se llama al abrir la app (en main.dart).
  static Future<void> cargar() async {
    final dni = await _dniProfesor();
    if (dni == null) return;

    try {
      final doc =
          await _db.collection('profesores').doc(dni).get().timeout(_espera);
      final texto = doc.data()?['datos'] as String?;
      if (texto != null) {
        final lista = jsonDecode(texto) as List;
        carreras
          ..clear()
          ..addAll(lista.map((c) => Carrera.fromJson(c)));
      }
      _cargado = true;
      await sincronizarAsistencias();
    } catch (e) {
      debugPrint('Error al leer de Firestore: $e');
    }
  }

  // Actualiza la lista de presentes de cada clase con lo que hay en la nube.
  static Future<void> sincronizarAsistencias() async {
    final dni = await _dniProfesor();
    if (dni == null) return;

    final snap = await _db
        .collection('asistencias')
        .where('profesor', isEqualTo: dni)
        .get()
        .timeout(_espera);

    final porClase = <String, List<Alumno>>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      porClase
          .putIfAbsent(data['claseId'] as String, () => [])
          .add(_alumnoDesdeDoc(data));
    }

    for (final carrera in carreras) {
      for (final materia in carrera.materias) {
        for (final clase in materia.clases) {
          final lista = porClase[clase.id] ?? [];
          lista.sort((a, b) => a.hora.compareTo(b.hora));
          clase.alumnos = lista;
        }
      }
    }
  }

  static Alumno _alumnoDesdeDoc(Map<String, dynamic> data) {
    return Alumno(
      nombre: data['nombre'] as String,
      registro: data['registro'] as int,
      dni: data['dni'] as int,
      hora: DateTime.parse(data['hora'] as String),
      nombreAnterior: data['nombreAnterior'] as String?,
      dniAnterior: data['dniAnterior'] as int?,
    );
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

  static Future<void> eliminarAsistenciaDispositivo(String claseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$claveAsistenciaDispositivo$claseId');
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

  // ---------------------------------------------------------------- QR

  // Texto que se guarda dentro del QR: aulacheck|idClase|momento|latitud|longitud
  static String generarQr(Clase clase, double latitud, double longitud) {
    return 'aulacheck|${clase.id}|${DateTime.now().millisecondsSinceEpoch}|$latitud|$longitud';
  }

  static ({double latitud, double longitud})? ubicacionQr(String codigo) {
    final partes = codigo.split('|');
    if (partes.length != 5 || partes[0] != 'aulacheck') return null;

    final latitud = double.tryParse(partes[3]);
    final longitud = double.tryParse(partes[4]);
    if (latitud == null || longitud == null) return null;
    if (latitud < -90 || latitud > 90 || longitud < -180 || longitud > 180) {
      return null;
    }
    return (latitud: latitud, longitud: longitud);
  }

  // El profesor publica en la nube cuál es el QR vigente de la clase.
  // Si genera uno nuevo, el anterior deja de servir.
  static Future<void> publicarQr(Clase clase, String qr) async {
    await _db.collection('clases').doc(clase.id).set({
      'qr': qr,
      'materia': clase.materia,
      'fecha': clase.fecha,
      'profesor': await _dniProfesor(),
    }).timeout(_espera);
  }

  // El QR no se cierra al salir de la pantalla: sigue valiendo hasta que venza
  // (10 minutos), así el profesor puede cerrar la app y volver sin perderlo.
  // Esta función devuelve el QR vigente de la clase, o null si no hay o ya venció.
  static Future<String?> qrVigente(String claseId) async {
    final doc =
        await _db.collection('clases').doc(claseId).get().timeout(_espera);
    final qr = doc.data()?['qr'] as String?;
    if (qr == null || qr.isEmpty) return null;

    final momento = momentoQr(qr);
    if (momento == null) return null;

    final edad = DateTime.now().difference(momento);
    return edad.inSeconds < minutosValidez * 60 ? qr : null;
  }

  // Momento en que se generó un QR (viene escrito dentro del propio texto del QR)
  static DateTime? momentoQr(String qr) {
    final partes = qr.split('|');
    if (partes.length != 5) return null;
    final ms = int.tryParse(partes[2]);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // Lo usa el alumno: devuelve los datos de la clase (id, materia, fecha, profesor)
  // si el QR es el vigente y no venció, o null si no sirve.
  static Future<Map<String, dynamic>?> validarQr(String codigo) async {
    final partes = codigo.split('|');
    if (partes.length != 5 || partes[0] != 'aulacheck') return null;

    final momento = int.tryParse(partes[2]);
    if (momento == null) return null;

    final edad = DateTime.now().millisecondsSinceEpoch - momento;
    if (edad > minutosValidez * 60 * 1000) return null;

    final doc =
        await _db.collection('clases').doc(partes[1]).get().timeout(_espera);
    final data = doc.data();
    if (data == null || data['qr'] != codigo) return null;

    return {...data, 'id': partes[1]};
  }

  // ------------------------------------------------------- Asistencias

  // El alumno registra su asistencia. Devuelve false si ya estaba registrado.
  // El documento se llama idClase_dni, así no se puede registrar dos veces.
  static Future<bool> registrarAsistenciaRemota(
    Map<String, dynamic> clase,
    Alumno alumno,
  ) async {
    final ref = _db.collection('asistencias').doc('${clase['id']}_${alumno.dni}');
    final existente = await ref.get().timeout(_espera);
    if (existente.exists) return false;

    await ref.set({
      'claseId': clase['id'],
      'profesor': clase['profesor'],
      'nombre': alumno.nombre,
      'dni': alumno.dni,
      'registro': alumno.registro,
      'hora': alumno.hora.toIso8601String(),
      // Solo si el alumno cambió sus datos desde la última vez (aviso para el profesor)
      if (alumno.nombreAnterior != null) 'nombreAnterior': alumno.nombreAnterior,
      if (alumno.dniAnterior != null) 'dniAnterior': alumno.dniAnterior,
    }).timeout(_espera);
    return true;
  }

  // El profesor ve en vivo quiénes están presentes en una clase.
  static Stream<List<Alumno>> escucharAsistencias(String claseId) {
    return _db
        .collection('asistencias')
        .where('claseId', isEqualTo: claseId)
        .snapshots()
        .map((snap) {
      final lista = snap.docs.map((d) => _alumnoDesdeDoc(d.data())).toList();
      lista.sort((a, b) => a.hora.compareTo(b.hora)); // orden de llegada
      return lista;
    });
  }

  static Future<void> eliminarAsistenciaRemota(String claseId, int dni) async {
    try {
      await _db
          .collection('asistencias')
          .doc('${claseId}_$dni')
          .delete()
          .timeout(_espera);
    } catch (e) {
      debugPrint('Error al eliminar la asistencia: $e');
    }
  }

  // Corrige nombre o DNI de un alumno. Si cambió el DNI cambia el nombre del documento.
  static Future<void> actualizarAsistenciaRemota(
    String claseId,
    int dniAnterior,
    Alumno alumno,
  ) async {
    try {
      if (dniAnterior != alumno.dni) {
        await _db
            .collection('asistencias')
            .doc('${claseId}_$dniAnterior')
            .delete()
            .timeout(_espera);
      }
      await _db.collection('asistencias').doc('${claseId}_${alumno.dni}').set({
        'claseId': claseId,
        'profesor': await _dniProfesor(),
        'nombre': alumno.nombre,
        'dni': alumno.dni,
        'registro': alumno.registro,
        'hora': alumno.hora.toIso8601String(),
      }).timeout(_espera);
    } catch (e) {
      debugPrint('Error al corregir la asistencia: $e');
    }
  }
}
