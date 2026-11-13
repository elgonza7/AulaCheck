import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'package:aulacheck/src/app.dart';
import 'package:aulacheck/src/config/tema_controller.dart';
import 'package:aulacheck/src/services/datos.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TemaController.cargar(); // recupera el tema (claro u oscuro) elegido
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Datos.cargar(); // recupera lo guardado en la nube antes de abrir la app
  runApp(const AulaCheckApp());
}
