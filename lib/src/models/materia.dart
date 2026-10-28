import 'alumno.dart';
import 'clase.dart';

class Materia {
  String nombre;
  String id;
  List<Clase> clases;

  Materia({
    required this.nombre,
    String? id,
    List<Clase>? clases,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        clases = clases ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'clases': clases.map((c) => c.toJson()).toList(),
      };

  factory Materia.fromJson(Map<String, dynamic> json) => Materia(
        id: json['id'],
        nombre: json['nombre'],
        clases: (json['clases'] as List).map((c) => Clase.fromJson(c)).toList(),
      );

  // Cuenta a cuántas clases fue cada alumno (por DNI) y lo ordena de mayor a menor.
  List<MapEntry<Alumno, int>> rankingAsistencia() {
    final Map<int, Alumno> alumnosPorDni = {};
    final Map<int, int> asistencias = {};

    for (final clase in clases) {
      for (final alumno in clase.alumnos) {
        alumnosPorDni[alumno.dni] = alumno;
        asistencias[alumno.dni] = (asistencias[alumno.dni] ?? 0) + 1;
      }
    }

    final ranking = asistencias.entries
        .map((e) => MapEntry(alumnosPorDni[e.key]!, e.value))
        .toList();
    ranking.sort((a, b) => b.value.compareTo(a.value));
    return ranking;
  }
}
