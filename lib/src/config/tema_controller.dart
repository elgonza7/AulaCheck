import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Guarda qué tema eligió el usuario (claro u oscuro) y avisa a la app cuando cambia.
//
// "modo" es un ValueNotifier: una variable que avisa a quien la escucha cuando
// cambia su valor. La app (app.dart) la escucha y se redibuja sola.
class TemaController {
  static final ValueNotifier<ThemeMode> modo = ValueNotifier(ThemeMode.dark);

  // Se llama una vez al abrir la app para recuperar la elección guardada
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
