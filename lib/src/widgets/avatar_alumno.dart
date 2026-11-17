import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:aulacheck/src/config/app_theme.dart';
import 'package:aulacheck/src/widgets/layout_base.dart';

// Avatar: la foto si tiene, si no las iniciales.
// La foto viene en base64 (así la guardo en Firestore y en el celu).
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

  // cache: si no, decodifica la foto en cada redibujo
  static final Map<String, Uint8List> _cache = {};

  static Uint8List? _bytes(String? foto) {
    if (foto == null || foto.isEmpty) return null;
    try {
      return _cache.putIfAbsent(foto, () => base64Decode(foto));
    } catch (_) {
      return null; // base64 roto -> muestro iniciales
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
