// Al profe no le guardo carrera ni materia porque puede tener varias,
// las crea después en "Mis carreras".
class Profesor {
  String nombre;
  String dni;
  String email;

  Profesor({
    required this.nombre,
    required this.dni,
    required this.email,
  });
}
