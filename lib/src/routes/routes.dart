import 'package:flutter/material.dart';
import 'package:aulacheck/src/pages/alumno/alumno_page.dart';
import 'package:aulacheck/src/pages/profesor/professor_page.dart';
import 'package:aulacheck/src/pages/home/home_page.dart';
import 'package:aulacheck/src/pages/profesor/carreras_page.dart';
import 'package:aulacheck/src/pages/settings/settings_page.dart';

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