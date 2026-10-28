import 'materia.dart';

// Una carrera tiene varias materias, y cada materia varias clases.
class Carrera {
  String nombre;
  List<Materia> materias;

  Carrera({required this.nombre, List<Materia>? materias})
      : materias = materias ?? [];

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'materias': materias.map((m) => m.toJson()).toList(),
      };

  factory Carrera.fromJson(Map<String, dynamic> json) => Carrera(
        nombre: json['nombre'],
        materias:
            (json['materias'] as List).map((m) => Materia.fromJson(m)).toList(),
      );
}
