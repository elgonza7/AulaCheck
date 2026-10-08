import 'package:flutter/material.dart';
import 'src/routes/routes.dart';
import 'src/utiles/datos.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Datos.cargar(); // recupera lo guardado antes de abrir la app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AulaCheck',
      debugShowCheckedModeBanner: false,
      initialRoute: Rutas.home,
      onGenerateRoute: Rutas.generarRuta,
    );
  }
}