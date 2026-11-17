class Alumno {
  String nombre;
  int registro;
  int dni;
  DateTime hora; // hora en que escaneó

  // Datos viejos: solo se llenan si cambió nombre/DNI desde su última asistencia.
  // Con esto le sale el aviso naranja al profe.
  String? nombreAnterior;
  int? dniAnterior;

  // Foto en base64. Va en la asistencia para que el profe vea quién es.
  // OJO: no la meto en toJson, si no el documento del profe se llena de fotos
  // (Firestore tiene límite de 1 MB por documento).
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

  // toJson = objeto -> Map para guardar / fromJson = al revés, al leer
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
