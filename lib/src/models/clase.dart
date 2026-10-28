import 'alumno.dart';

class Clase {
  String id;
  String nombre;
  String materia;
  List<Alumno> alumnos; // alumnos que estuvieron presentes
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

  // Fecha con formato 21/09/2026
  String get fecha {
    final d = fechaCreacion.day.toString().padLeft(2, '0');
    final m = fechaCreacion.month.toString().padLeft(2, '0');
    return '$d/$m/${fechaCreacion.year}';
  }

  // Devuelve false si el alumno ya estaba registrado en esta clase
  bool registrarAsistencia(Alumno alumno) {
    final yaEsta = alumnos.any((a) => a.dni == alumno.dni);
    if (yaEsta) return false;
    alumnos.add(alumno);
    return true;
  }
}
