import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:aulacheck/src/config/app_theme.dart';
import 'package:aulacheck/src/widgets/layout_base.dart';

// Avatar redondo: muestra la foto del alumno si tiene, o sus iniciales si no.
// La foto viene como texto "base64" (así se guarda en Firestore y en el celular).
class AvatarAlumno extends StatelessWidget {
  final String nombre;
  final String? foto; // base64 o null
  final double radio;

  const AvatarAlumno({
    super.key,
    required this.nombre,
    this.foto,
    this.radio = 20,
  });

  // Guarda las fotos ya convertidas para no decodificarlas en cada redibujo
  static final Map<String, Uint8List> _cache = {};

  static Uint8List? _bytes(String? foto) {
    if (foto == null || foto.isEmpty) return null;
    try {
      return _cache.putIfAbsent(foto, () => base64Decode(foto));
    } catch (_) {
      return null; // texto dañado: se muestran las iniciales
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes(foto);
    return CircleAvatar(
      radius: radio,
      backgroundColor: AppTheme.violeta,
      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
      child: bytes != null
          ? null
          : Text(
              iniciales(nombre),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: radio * 0.7,
              ),
            ),
    );
  }
}
