import 'alumno.dart';

class Clase {
  String id;
  String nombre;
  String materia;
  List<Alumno> alumnos; // los presentes
  DateTime fechaCreacion;

  Clase({
    required this.nombre,
    required this.materia,
    required this.alumnos,
    String? id,
    DateTime? fechaCreacion,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        fechaCreacion = fechaCreacion ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'materia': materia,
        'fechaCreacion': fechaCreacion.toIso8601String(),
        'alumnos': alumnos.map((a) => a.toJson()).toList(),
      };

  factory Clase.fromJson(Map<String, dynamic> json) => Clase(
        id: json['id'],
        nombre: json['nombre'],
        materia: json['materia'],
        fechaCreacion: DateTime.parse(json['fechaCreacion']),
        alumnos: (json['alumnos'] as List)
            .map((a) => Alumno.fromJson(a))
            .toList(),
      );

  // para mostrar tipo 21/09/2026
  String get fecha => formatoFecha(fechaCreacion);

  static String formatoFecha(DateTime dia) {
    final d = dia.day.toString().padLeft(2, '0');
    final m = dia.month.toString().padLeft(2, '0');
    return '$d/$m/${dia.year}';
  }

  // Una clase = un día. Si no es de hoy, no deja activar el QR
  bool get esDeHoy => fecha == formatoFecha(DateTime.now());

  // false si ese alumno ya estaba (no lo duplica)
  bool registrarAsistencia(Alumno alumno) {
    final yaEsta = alumnos.any((a) => a.dni == alumno.dni);
    if (yaEsta) return false;
    alumnos.add(alumno);
    return true;
  }
}
