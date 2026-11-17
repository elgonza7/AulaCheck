import 'package:flutter/material.dart';

// Acá están todos los colores y estilos de la app.
// Los dos temas salen de la misma función (_construir), solo cambia la paleta.
// Si quiero cambiar cómo se ve algo, primero me fijo acá.
// (el claro todavía hay que pulirlo, queda para el final)
class AppTheme {
  static const Color violeta = Color(0xFF8A2BE2);
  static const Color exito = Color(0xFF4CAF50);
  static const double radio = 14;

  static ThemeData get oscuro => _construir(Brightness.dark);
  static ThemeData get claro => _construir(Brightness.light);

  static ThemeData _construir(Brightness brillo) {
    final esOscuro = brillo == Brightness.dark;

    // Paleta: esto es lo único que cambia entre oscuro y claro
    final fondo = esOscuro ? const Color(0xFF101010) : const Color(0xFFF5F3FA);
    final tarjeta = esOscuro ? const Color(0xFF1A1A1A) : Colors.white;
    final borde = esOscuro ? const Color(0xFF2E2E2E) : const Color(0xFFDDD8EA);
    final texto = esOscuro ? Colors.white : const Color(0xFF1B1B1F);
    final textoSuave = esOscuro ? Colors.white54 : Colors.black54;
    final deshabilitado =
        esOscuro ? const Color(0xFF2A2A2A) : const Color(0xFFE4E0EC);

    final esquema = ColorScheme.fromSeed(
      seedColor: violeta,
      brightness: brillo,
    ).copyWith(
      primary: violeta,
      onPrimary: Colors.white,
      surface: tarjeta,
      onSurface: texto,
      onSurfaceVariant: textoSuave,
    );

    final formaRedondeada = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radio),
    );

    return ThemeData(
      brightness: brillo,
      scaffoldBackgroundColor: fondo,
      colorScheme: esquema,
      appBarTheme: AppBarTheme(
        backgroundColor: fondo,
        foregroundColor: texto,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: tarjeta,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radio),
          side: BorderSide(color: borde),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: violeta,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: violeta,
          foregroundColor: Colors.white,
          disabledBackgroundColor: deshabilitado,
          disabledForegroundColor: esOscuro ? Colors.white38 : Colors.black38,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: formaRedondeada,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: formaRedondeada),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: esOscuro ? Colors.white70 : violeta,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: violeta,
        foregroundColor: Colors.white,
        shape: formaRedondeada,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tarjeta,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radio),
          borderSide: BorderSide(color: borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radio),
          borderSide: BorderSide(color: borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radio),
          borderSide: const BorderSide(color: violeta, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tarjeta,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: esOscuro ? const Color(0xFF2A2A2A) : const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: formaRedondeada,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: violeta),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? Colors.white
              : (esOscuro ? Colors.white70 : Colors.black45),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (estados) =>
              estados.contains(WidgetState.selected) ? violeta : deshabilitado,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.selected)
                ? violeta
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (estados) =>
                estados.contains(WidgetState.selected) ? Colors.white : texto,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: borde),
    );
  }
}

// context.textoSuave -> el gris para textos secundarios
// (extensión para no escribir Theme.of(context)... cada vez, anda en los dos temas)
extension TemaContexto on BuildContext {
  Color get textoSuave => Theme.of(this).colorScheme.onSurfaceVariant;
}
