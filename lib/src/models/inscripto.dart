// Inscripto = un alumno del padrón (la lista que carga el profe).
// No confundir con Alumno: Alumno es una asistencia (alguien que escaneó).
class Inscripto {
  String nombre;
  int dni;

  Inscripto({required this.nombre, required this.dni});

  Map<String, dynamic> toJson() => {'nombre': nombre, 'dni': dni};

  factory Inscripto.fromJson(Map<String, dynamic> json) => Inscripto(
        nombre: json['nombre'],
        dni: json['dni'],
      );
}
