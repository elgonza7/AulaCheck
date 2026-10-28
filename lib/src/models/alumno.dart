class Alumno {
  String nombre;
  int registro;
  int dni;
  DateTime hora; // cuándo se registró la asistencia

  Alumno({
    required this.nombre,
    required this.registro,
    required this.dni,
    DateTime? hora,
  }) : hora = hora ?? DateTime.now();

  // toJson / fromJson: pasan el objeto a texto para guardarlo y lo reconstruyen al leerlo
  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'registro': registro,
        'dni': dni,
        'hora': hora.toIso8601String(),
      };

  factory Alumno.fromJson(Map<String, dynamic> json) => Alumno(
        nombre: json['nombre'],
        registro: json['registro'],
        dni: json['dni'],
        hora: DateTime.parse(json['hora']),
      );
}
