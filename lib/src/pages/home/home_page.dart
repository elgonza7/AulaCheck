import 'package:flutter/material.dart';
import 'package:aulacheck/src/config/app_theme.dart';
import 'package:aulacheck/src/widgets/layout_base.dart';
import 'package:aulacheck/src/pages/alumno/alumno_page.dart';
import 'package:aulacheck/src/pages/profesor/professor_page.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBase(
      titulo: 'Bienvenido',
      subtitulo: '¿Cómo vas a usar AulaCheck?',
      hijo: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            OpcionInicio(
              icono: Icons.school_outlined,
              titulo: 'Soy Profesor',
              descripcion:
                  'Podrás crear carreras, materias y clases, y registrar la asistencia con un QR',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const ProfessorPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            OpcionInicio(
              icono: Icons.badge_outlined,
              titulo: 'Soy Alumno',
              descripcion: 'Escaneá el QR de la clase para registrar tu asistencia',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const AlumnoPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OpcionInicio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  const OpcionInicio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radio = BorderRadius.all(Radius.circular(16));

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: radio,
      child: InkWell(
        onTap: onTap,
        borderRadius: radio,
        hoverColor: const Color(0x338A2BE2),
        splashColor: const Color(0x668A2BE2),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF8A2BE2), width: 1.5),
            borderRadius: radio,
          ),
          child: Row(
            children: [
              Icon(icono, color: const Color(0xFF8A2BE2), size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(color: context.textoSuave, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                color: Color(0xFF8A2BE2),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}