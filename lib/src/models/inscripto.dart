// Un alumno del padrón de una materia (la lista oficial de inscriptos que carga el profesor).
// No es lo mismo que Alumno: Alumno es una asistencia (alguien que escaneó un QR).
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
