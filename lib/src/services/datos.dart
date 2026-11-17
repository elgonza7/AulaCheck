import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aulacheck/src/models/models.dart';

// Datos compartidos entre pantallas.
// Se guardan en Firestore (la nube), así el profesor puede cambiar de celular
// y los alumnos pueden usar el suyo.
//
// El profesor inicia sesión con email y contraseña (Firebase Authentication).
// Cada profesor tiene un "uid": un identificador único que le da Firebase.
//
// Colecciones de Firestore:
//   profesores/{uid}            -> perfil del profesor + árbol de carreras, materias y clases
//   clases/{idClase}            -> QR activo de la clase (lo escribe el profesor, lo lee el alumno)
//   asistencias/{idClase}_{dni} -> un documento por alumno presente
class Datos {
  static Profesor? profesor;
  static final List<Carrera> carreras = [];

  // Ajustes del QR (se cambian en la pantalla de Ajustes)
  static int minutosQr = 10; // cuánto dura un QR activo
  static int radioMetros = 100; // a qué distancia del profesor tiene que estar el alumno

  static const String claveAsistenciaDispositivo = 'asistencia_dispositivo_';

  // Evita pisar lo guardado en la nube con una lista vacía si todavía no se pudo leer
  static bool _cargado = false;

  static const Duration _espera = Duration(seconds: 8);

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  // Identificador del profesor que inició sesión (null si no hay nadie)
  static String? get _uid => _auth.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>> _docProfesor(String uid) =>
      _db.collection('profesores').doc(uid);

  // ----------------------------------------------------------- Sesión

  // Crea la cuenta del profesor y guarda su perfil en la nube
  static Future<void> registrarProfesor({
    required String nombre,
    required String dni,
    required String email,
    required String contrasena,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: contrasena,
    );
    await _docProfesor(cred.user!.uid).set({
      'nombre': nombre,
      'dni': dni,
      'email': email,
      'datos': '[]',
    });
    await cargar();
  }

  static Future<void> iniciarSesion(String email, String contrasena) async {
    await _auth.signInWithEmailAndPassword(email: email, password: contrasena);
    await cargar();
  }

  static Future<void> cerrarSesion() async {
    await _auth.signOut();
    profesor = null;
    carreras.clear();
    _cargado = false;
  }

  // Cambia nombre y DNI del profesor (el email no se toca)
  static Future<void> actualizarPerfil(String nombre, String dni) async {
    final uid = _uid;
    if (uid == null || profesor == null) return;
    await _docProfesor(uid)
        .set({'nombre': nombre, 'dni': dni}, SetOptions(merge: true))
        .timeout(_espera);
    profesor!.nombre = nombre;
    profesor!.dni = dni;
  }

  // Traduce los errores de Firebase a mensajes entendibles
  static String mensajeError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'El email no es válido';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email o contraseña incorrectos';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con ese email';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres';
        case 'operation-not-allowed':
          return 'Falta activar "Email/Password" en Firebase Authentication';
        case 'network-request-failed':
          return 'Sin conexión a internet';
      }
      return e.message ?? e.code;
    }
    return e.toString();
  }

  // ----------------------------------------------------------- Guardar y leer

  // Guarda todas las carreras (con sus materias y clases) en la nube.
  // Hay que llamarla cada vez que se cambia algo.
  static Future<void> guardar() async {
    final uid = _uid;
    if (uid == null) return;
    if (!_cargado) {
      debugPrint('No se guardó: todavía no se pudo leer lo que había en la nube');
      return;
    }

    try {
      final texto = jsonEncode(carreras.map((c) => c.toJson()).toList());
      await _docProfesor(uid)
          .set({'datos': texto}, SetOptions(merge: true))
          .timeout(_espera);
    } catch (e) {
      debugPrint('Error al guardar en Firestore: $e');
    }
  }

  // Lee el perfil y los datos del profesor que inició sesión.
  // Se llama al abrir la app (main.dart) y al iniciar sesión.
  static Future<void> cargar() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final doc = await _docProfesor(uid).get().timeout(_espera);
      final data = doc.data() ?? {};

      profesor = Profesor(
        nombre: data['nombre'] as String? ?? '',
        dni: data['dni'] as String? ?? '',
        email: data['email'] as String? ?? _auth.currentUser?.email ?? '',
      );

      final texto = data['datos'] as String?;
      carreras.clear();
      if (texto != null) {
        final lista = jsonDecode(texto) as List;
        carreras.addAll(lista.map((c) => Carrera.fromJson(c)));
      }
      _cargado = true;
      await sincronizarAsistencias();
    } catch (e) {
      debugPrint('Error al leer de Firestore: $e');
    }
  }

  // Actualiza la lista de presentes de cada clase con lo que hay en la nube.
  static Future<void> sincronizarAsistencias() async {
    final uid = _uid;
    if (uid == null) return;

    final snap = await _db
        .collection('asistencias')
        .where('profesor', isEqualTo: uid)
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
      foto: data['foto'] as String?,
    );
  }

  // ----------------------------------------------------------- Ajustes

  static Future<void> cargarAjustes() async {
    final prefs = await SharedPreferences.getInstance();
    minutosQr = prefs.getInt('ajuste_minutos_qr') ?? 10;
    radioMetros = prefs.getInt('ajuste_radio') ?? 100;
  }

  static Future<void> guardarAjustes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ajuste_minutos_qr', minutosQr);
    await prefs.setInt('ajuste_radio', radioMetros);
  }

  // ----------------------------------------------------------- Dispositivo del alumno

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

  // Momento en que se generó un QR (viene escrito dentro del propio texto del QR)
  static DateTime? momentoQr(String qr) {
    final partes = qr.split('|');
    if (partes.length != 5) return null;
    final ms = int.tryParse(partes[2]);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // El profesor activa el QR: queda publicado en la nube junto con su duración
  // y la distancia máxima permitida. Si había otro, el anterior deja de servir.
  static Future<void> publicarQr(Clase clase, String qr) async {
    await _db.collection('clases').doc(clase.id).set({
      'qr': qr,
      'materia': clase.materia,
      'fecha': clase.fecha,
      'profesor': _uid,
      'minutos': minutosQr,
      'radio': radioMetros,
    }).timeout(_espera);
  }

  // El profesor desactiva el QR: desde ese momento nadie más puede registrarse
  static Future<void> desactivarQr(String claseId) async {
    await _db
        .collection('clases')
        .doc(claseId)
        .set({'qr': ''}, SetOptions(merge: true))
        .timeout(_espera);
  }

  // Cuándo vence un QR activo, o null si no hay QR activo (o ya venció).
  // Se usa al abrir la pantalla de la clase para mostrar el mismo QR que estaba.
  static Future<({String qr, DateTime vence})?> qrActivo(String claseId) async {
    final doc =
        await _db.collection('clases').doc(claseId).get().timeout(_espera);
    final data = doc.data();
    final qr = data?['qr'] as String?;
    if (qr == null || qr.isEmpty) return null;

    final momento = momentoQr(qr);
    if (momento == null) return null;

    final minutos = data?['minutos'] as int? ?? 10;
    final vence = momento.add(Duration(minutes: minutos));
    if (!DateTime.now().isBefore(vence)) return null;
    return (qr: qr, vence: vence);
  }

  // Lo usa el alumno: devuelve los datos de la clase (id, materia, fecha,
  // profesor, radio) si el QR es el activo y no venció, o null si no sirve.
  static Future<Map<String, dynamic>?> validarQr(String codigo) async {
    final partes = codigo.split('|');
    if (partes.length != 5 || partes[0] != 'aulacheck') return null;

    final momento = momentoQr(codigo);
    if (momento == null) return null;

    final doc =
        await _db.collection('clases').doc(partes[1]).get().timeout(_espera);
    final data = doc.data();
    if (data == null || data['qr'] != codigo) return null;

    final minutos = data['minutos'] as int? ?? 10;
    if (DateTime.now().difference(momento).inSeconds > minutos * 60) return null;

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
      if (alumno.foto != null) 'foto': alumno.foto,
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
        'profesor': _uid,
        'nombre': alumno.nombre,
        'dni': alumno.dni,
        'registro': alumno.registro,
        'hora': alumno.hora.toIso8601String(),
        if (alumno.foto != null) 'foto': alumno.foto,
      }).timeout(_espera);
    } catch (e) {
      debugPrint('Error al corregir la asistencia: $e');
    }
  }
}
