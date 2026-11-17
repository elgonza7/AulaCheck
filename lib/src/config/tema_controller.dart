import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Guarda si elegí tema claro u oscuro (SharedPreferences, clave tema_oscuro).
//
// modo es un ValueNotifier = una variable que avisa cuando cambia.
// app.dart la escucha con ValueListenableBuilder y se redibuja sola, sin setState.
class TemaController {
  static final ValueNotifier<ThemeMode> modo = ValueNotifier(ThemeMode.dark);

  // Lo llamo en main() antes de runApp
  static Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final oscuro = prefs.getBool('tema_oscuro') ?? true;
    modo.value = oscuro ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> cambiar(bool oscuro) async {
    modo.value = oscuro ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tema_oscuro', oscuro);
  }
}
