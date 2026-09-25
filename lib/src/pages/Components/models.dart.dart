
class Alumno {
  String nombre;
  int registro;
  int dni;

  Alumno({required this.nombre, required this.registro, required this.dni});
}

class Clase {
  String nombre;
  String materia;
  List<Alumno> alumnos;
  DateTime fechaCreacion;

  Clase({
    required this.nombre, 
    required this.materia, 
    required this.alumnos,
  }) : fechaCreacion = DateTime.now(); // Inicialización limpia
}

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
}