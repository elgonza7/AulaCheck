import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aulacheck/src/models/models.dart';

// Todo lo de Firebase está acá (los datos que usan varias pantallas).
// Lo pasé a la nube para que el profe pueda cambiar de celu sin perder nada,
// y cada alumno usa el suyo.
//
// Login del profe: email + contraseña (Firebase Authentication).
// uid = el id único que Firebase le da a cada profe.
//
// Colecciones de Firestore:
//   profesores/{uid}            -> perfil del profesor + árbol de carreras, materias y clases
//   clases/{idClase}            -> QR activo de la clase (lo escribe el profesor, lo lee el alumno)
//   asistencias/{idClase}_{dni} -> un documento por alumno presente
class Datos {
  static Profesor? profesor;
  static final List<Carrera> carreras = [];

  // ajustes del QR (pantalla Ajustes)
  static int minutosQr = 10; // cuánto dura el QR
  static int radioMetros = 100; // radio en metros alrededor del profe

  static const String claveAsistenciaDispositivo = 'asistencia_dispositivo_';

  // para no pisar la nube con una lista vacía si todavía no se leyó nada
  static bool _cargado = false;

  static const Duration _espera = Duration(seconds: 8);

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  // uid del profe logueado (null = nadie)
  static String? get _uid => _auth.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>> _docProfesor(String uid) =>
      _db.collection('profesores').doc(uid);

  // ----------------------------------------------------------- Sesión

  // registro: crea la cuenta en Auth y el perfil en Firestore
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

  // editar perfil: nombre y DNI (el email no)
  static Future<void> actualizarPerfil(String nombre, String dni) async {
    final uid = _uid;
    if (uid == null || profesor == null) return;
    await _docProfesor(uid)
        .set({'nombre': nombre, 'dni': dni}, SetOptions(merge: true))
        .timeout(_espera);
    profesor!.nombre = nombre;
    profesor!.dni = dni;
  }

  // errores de Firebase -> mensajes en castellano
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

  // Sube todas las carreras (con materias y clases) a la nube.
  // OJO: llamarla cada vez que cambio algo, si no, no se guarda.
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

  // Trae el perfil y los datos del profe logueado.
  // Se llama en main() y cuando inicia sesión.
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

  // rellena los presentes de cada clase con lo que hay en asistencias
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

  // un celu = una asistencia por clase (candado en SharedPreferences)
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

  // formato del QR: aulacheck|idClase|momento|latitud|longitud (separado con |)
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

  // saco el momento del propio texto del QR (partes[2])
  static DateTime? momentoQr(String qr) {
    final partes = qr.split('|');
    if (partes.length != 5) return null;
    final ms = int.tryParse(partes[2]);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // Activar: subo el QR a clases/{id} con los minutos y el radio.
  // Si había otro, el viejo ya no coincide y deja de servir.
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

  // desactivar: pongo qr = '' y listo, nadie más se registra
  static Future<void> desactivarQr(String claseId) async {
    await _db
        .collection('clases')
        .doc(claseId)
        .set({'qr': ''}, SetOptions(merge: true))
        .timeout(_espera);
  }

  // Cuándo vence el QR activo (null = no hay o ya venció).
  // Lo uso al reabrir la clase para mostrar el mismo QR.
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

  // Lo usa el alumno: si el QR es el activo y no venció devuelve los datos
  // de la clase (id, materia, fecha, profesor, radio). Si no, null.
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

  // Registra la asistencia. false = ya estaba.
  // El doc se llama idClase_dni -> el mismo DNI no puede estar dos veces.
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
      // solo si cambió datos (aviso para el profe)
      if (alumno.nombreAnterior != null) 'nombreAnterior': alumno.nombreAnterior,
      if (alumno.dniAnterior != null) 'dniAnterior': alumno.dniAnterior,
      if (alumno.foto != null) 'foto': alumno.foto,
    }).timeout(_espera);
    return true;
  }

  // Stream: el profe ve en vivo quién va llegando.
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

  // corregir nombre/DNI. Si cambia el DNI cambia el id del doc (borro el viejo)
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
