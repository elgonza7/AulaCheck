import 'alumno.dart';
import 'clase.dart';
import 'inscripto.dart';

class Materia {
  String nombre;
  String id;
  List<Clase> clases;
  List<Inscripto> inscriptos; // padrón de alumnos de la materia

  Materia({
    required this.nombre,
    String? id,
    List<Clase>? clases,
    List<Inscripto>? inscriptos,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        clases = clases ?? [],
        inscriptos = inscriptos ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'clases': clases.map((c) => c.toJson()).toList(),
        'inscriptos': inscriptos.map((i) => i.toJson()).toList(),
      };

  factory Materia.fromJson(Map<String, dynamic> json) => Materia(
        id: json['id'],
        nombre: json['nombre'],
        clases: (json['clases'] as List).map((c) => Clase.fromJson(c)).toList(),
        // "?? []" porque las materias guardadas antes no tenían padrón
        inscriptos: (json['inscriptos'] as List? ?? [])
            .map((i) => Inscripto.fromJson(i))
            .toList(),
      );

  // Busca un alumno del padrón por DNI (null si no está inscripto)
  Inscripto? inscriptoPorDni(int dni) =>
      inscriptos.where((i) => i.dni == dni).firstOrNull;

  // A cuántas clases fue un alumno
  int asistenciasDe(int dni) =>
      clases.where((c) => c.alumnos.any((a) => a.dni == dni)).length;

  // Alumnos que se registraron con un nombre distinto al del padrón
  // (mismo DNI, otro nombre). Puede ser un error o alguien cambiando datos.
  List<({Alumno alumno, Clase clase, Inscripto inscripto})> nombresDistintos() {
    final lista = <({Alumno alumno, Clase clase, Inscripto inscripto})>[];
    for (final clase in clases) {
      for (final alumno in clase.alumnos) {
        final ins = inscriptoPorDni(alumno.dni);
        if (ins != null &&
            ins.nombre.trim().toLowerCase() != alumno.nombre.trim().toLowerCase()) {
          lista.add((alumno: alumno, clase: clase, inscripto: ins));
        }
      }
    }
    return lista;
  }

  // Alumnos que registraron asistencia pero no están en el padrón (uno por DNI)
  List<Alumno> registradosSinInscribir() {
    final porDni = <int, Alumno>{};
    for (final clase in clases) {
      for (final alumno in clase.alumnos) {
        if (inscriptoPorDni(alumno.dni) == null) porDni[alumno.dni] = alumno;
      }
    }
    return porDni.values.toList();
  }

  // Alumnos que cambiaron sus datos entre una clase y otra (con la clase donde se notó).
  // Es solo un aviso para el profesor, no bloquea nada.
  List<({Alumno alumno, Clase clase})> avisosCambioDatos() {
    final avisos = <({Alumno alumno, Clase clase})>[];
    for (final clase in clases) {
      for (final alumno in clase.alumnos) {
        if (alumno.cambioDatos) avisos.add((alumno: alumno, clase: clase));
      }
    }
    return avisos;
  }

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
