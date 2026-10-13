import 'package:flutter/material.dart';
import '../pages/alumno_page.dart';
import '../pages/professor_page.dart';
import '../pages/home_page.dart';
import '../pages/carreras_page.dart';
import '../pages/settings_page.dart';

class Rutas {
  static const String home = '/';
  static const String profesor = '/profesor';
  static const String alumno = '/alumno';
  static const String carreras = '/carreras';
  static const String ajustes = '/ajustes';

  static Route<dynamic> generarRuta(RouteSettings cfg) {
    switch (cfg.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      
      case profesor:
        return MaterialPageRoute(builder: (_) => const ProfessorPage());
      
      case alumno:
        return MaterialPageRoute(builder: (_) => const AlumnoPage());
      
      case carreras:
        return MaterialPageRoute(builder: (_) => const CarrerasPage());
      case ajustes:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      default:
        return MaterialPageRoute(builder: (_) => const HomePage());
    }
  }
}