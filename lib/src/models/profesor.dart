// El profesor ya no guarda carrera ni materia: puede tener varias,
// y se crean desde "Mis carreras".
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
