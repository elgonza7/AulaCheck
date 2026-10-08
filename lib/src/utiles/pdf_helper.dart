import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../pages/Components/models.dart';

String _hora(DateTime h) =>
    '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';

// PDF con los presentes de UNA clase, en el orden que se le pase.
Future<void> pdfClase(Materia materia, Clase clase, List<Alumno> alumnos) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      build: (_) => [
        pw.Header(level: 0, child: pw.Text('${materia.nombre} - ${clase.fecha}')),
        pw.Text('Presentes: ${alumnos.length}'),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['#', 'Nombre', 'DNI', 'Hora'],
          data: [
            for (var i = 0; i < alumnos.length; i++)
              ['${i + 1}', alumnos[i].nombre, '${alumnos[i].dni}', _hora(alumnos[i].hora)],
          ],
        ),
      ],
    ),
  );
  await Printing.layoutPdf(
    name: '${materia.nombre}_${clase.fecha.replaceAll('/', '-')}',
    onLayout: (_) async => doc.save(),
  );
}

// PDF de toda la materia: alumnos de mayor a menor asistencia
// y columnas vacías para completar las notas.
Future<void> pdfMateria(Materia materia) async {
  final ranking = materia.rankingAsistencia();
  final total = materia.clases.length;

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      build: (_) => [
        pw.Header(level: 0, child: pw.Text('${materia.nombre} - Asistencia')),
        pw.Text('Clases dictadas: $total'),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['#', 'Nombre', 'DNI', 'Asistencias', 'Nota 1', 'Nota 2', 'Nota Final'],
          data: [
            for (var i = 0; i < ranking.length; i++)
              [
                '${i + 1}',
                ranking[i].key.nombre,
                '${ranking[i].key.dni}',
                '${ranking[i].value}/$total',
                '', '', '',
              ],
          ],
        ),
      ],
    ),
  );
  await Printing.layoutPdf(
    name: '${materia.nombre}_asistencia',
    onLayout: (_) async => doc.save(),
  );
}
