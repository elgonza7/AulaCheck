import 'package:flutter/material.dart';

import 'package:aulacheck/src/config/app_theme.dart';

// Lo que se ve cuando una lista está vacía (sin carreras, sin clases...).
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String mensaje;

  const EstadoVacio({super.key, required this.icono, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 64, color: context.textoSuave.withAlpha(110)),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textoSuave, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
