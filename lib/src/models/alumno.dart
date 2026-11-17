class Alumno {
  String nombre;
  int registro;
  int dni;
  DateTime hora; // cuándo se registró la asistencia

  // Si el alumno cambió sus datos desde la última vez que registró asistencia,
  // acá quedan los datos que tenía antes. Sirve para avisarle al profesor.
  String? nombreAnterior;
  int? dniAnterior;

  // Foto del alumno (texto base64). Viaja con la asistencia para que el profesor
  // vea la cara de quien se registró. No se guarda dentro de las materias del
  // profesor (toJson) para no llenar ese documento.
  String? foto;

  Alumno({
    required this.nombre,
    required this.registro,
    required this.dni,
    DateTime? hora,
    this.nombreAnterior,
    this.dniAnterior,
    this.foto,
  }) : hora = hora ?? DateTime.now();

  bool get cambioDatos => dniAnterior != null;

  // toJson / fromJson: pasan el objeto a texto para guardarlo y lo reconstruyen al leerlo
  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'registro': registro,
        'dni': dni,
        'hora': hora.toIso8601String(),
        if (nombreAnterior != null) 'nombreAnterior': nombreAnterior,
        if (dniAnterior != null) 'dniAnterior': dniAnterior,
      };

  factory Alumno.fromJson(Map<String, dynamic> json) => Alumno(
        nombre: json['nombre'],
        registro: json['registro'],
        dni: json['dni'],
        hora: DateTime.parse(json['hora']),
        nombreAnterior: json['nombreAnterior'],
        dniAnterior: json['dniAnterior'],
      );
}
