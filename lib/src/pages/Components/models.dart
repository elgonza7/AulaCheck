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

class Profesor {
  String nombre;
  String dni;
  String carrera;
  String materia;

  Profesor({
    required this.nombre,
    required this.dni,
    required this.carrera,
    required this.materia,
  });
}

class Clase {
  String id;
  String nombre;
  String materia;
  List<Alumno> alumnos; // alumnos que estuvieron presentes
  DateTime fechaCreacion;

  Clase({
    required this.nombre,
    required this.materia,
    required this.alumnos,
    String? id,
    DateTime? fechaCreacion,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        fechaCreacion = fechaCreacion ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'materia': materia,
        'fechaCreacion': fechaCreacion.toIso8601String(),
        'alumnos': alumnos.map((a) => a.toJson()).toList(),
      };

  factory Clase.fromJson(Map<String, dynamic> json) => Clase(
        id: json['id'],
        nombre: json['nombre'],
        materia: json['materia'],
        fechaCreacion: DateTime.parse(json['fechaCreacion']),
        alumnos: (json['alumnos'] as List)
            .map((a) => Alumno.fromJson(a))
            .toList(),
      );

  // Fecha con formato 21/09/2026
  String get fecha {
    final d = fechaCreacion.day.toString().padLeft(2, '0');
    final m = fechaCreacion.month.toString().padLeft(2, '0');
    return '$d/$m/${fechaCreacion.year}';
  }

  // Devuelve false si el alumno ya estaba registrado en esta clase
  bool registrarAsistencia(Alumno alumno) {
    final yaEsta = alumnos.any((a) => a.dni == alumno.dni);
    if (yaEsta) return false;
    alumnos.add(alumno);
    return true;
  }
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
