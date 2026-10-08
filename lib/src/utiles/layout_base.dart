import 'package:flutter/material.dart';

class LayoutBase extends StatelessWidget {
  final Widget hijo;
  final String titulo;
  final String subtitulo;

  const LayoutBase({
    super.key,
    required this.hijo,
    this.titulo = '',
    this.subtitulo = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: 20),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'AULA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'CHECK',
                      style: TextStyle(
                        color: Color(0xFF8A2BE2),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (titulo.isNotEmpty)
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 10),
              if (subtitulo.isNotEmpty)
                Text(
                  subtitulo,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 40),
              Expanded(child: hijo),
            ],
          ),
        ),
      ),
    );
  }
}