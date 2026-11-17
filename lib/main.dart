import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'package:aulacheck/src/app.dart';
import 'package:aulacheck/src/config/tema_controller.dart';
import 'package:aulacheck/src/services/datos.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TemaController.cargar(); // el tema que quedó guardado (claro/oscuro)
  await Datos.cargarAjustes(); // minutos del QR y radio (de Ajustes)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Datos.cargar(); // si el profe ya estaba logueado, trae sus carreras de Firebase
  runApp(const AulaCheckApp());
}
