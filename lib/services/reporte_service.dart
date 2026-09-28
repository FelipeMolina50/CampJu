import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/evento_model.dart';
import '../models/inscripcion_model.dart';

class ReporteService {
  /// Exporta el listado de inscritos a un archivo CSV estructurado (compatible con Excel/Sheets con UTF-8 BOM)
  /// y lanza el diálogo nativo de compartir para guardar o enviar.
  static Future<void> exportarInscripcionesCsv({
    required EventoModel evento,
    required List<InscripcionModel> inscripciones,
    Map<String, String> nombresBosques = const {},
    Map<String, String> nombresCoordinadores = const {},
  }) async {
    final buffer = StringBuffer();

    // Byte Order Mark (BOM) UTF-8 para que Microsoft Excel lo abra con tildes y caracteres en español correctamente
    buffer.write('\uFEFF');

    // Encabezado principal del reporte
    buffer.writeln('REPORTE DE INSCRIPCIONES - CAMPJU');
    buffer.writeln('Evento:;${evento.titulo}');
    buffer.writeln('Tipo:;${evento.tipo.toUpperCase()}');
    buffer.writeln('Lugar / Sede:;${evento.lugar} - ${evento.municipioSede}');
    buffer.writeln('Fecha de Generacion:;${DateTime.now().toLocal().toString().split('.').first}');
    buffer.writeln('Total Inscritos Listados:;${inscripciones.length}');
    buffer.writeln('');

    // SECCION 1: RESUMEN POR MUNICIPIO Y BOSQUE
    buffer.writeln('--- RESUMEN POR MUNICIPIO Y BOSQUE ---');
    buffer.writeln('Municipio;Bosque;Coordinador;Total Inscritos');

    // Agrupación: municipio -> bosqueId -> listado
    final Map<String, Map<String, List<InscripcionModel>>> agrupado = {};

    for (final ins in inscripciones) {
      final mun = ins.municipio.trim().isEmpty ? 'Sin Municipio' : ins.municipio.trim();
      final bId = ins.bosqueId.trim().isEmpty ? 'Sin Bosque' : ins.bosqueId.trim();

      agrupado.putIfAbsent(mun, () => {});
      agrupado[mun]!.putIfAbsent(bId, () => []);
      agrupado[mun]![bId]!.add(ins);
    }

    final municipiosOrdenados = agrupado.keys.toList()..sort();
    for (final mun in municipiosOrdenados) {
      final bosquesMap = agrupado[mun]!;
      for (final entry in bosquesMap.entries) {
        final bId = entry.key;
        final count = entry.value.length;
        final bosqueNombre = nombresBosques[bId] ?? bId;
        final coordNombre = nombresCoordinadores[bId] ?? 'No asignado';
        buffer.writeln('$mun;$bosqueNombre;$coordNombre;$count');
      }
    }

    buffer.writeln('');

    // SECCION 2: DETALLE DE INSCRITOS
    buffer.writeln('--- LISTADO DETALLADO DE INSCRITOS ---');
    buffer.writeln('Municipio;Bosque;Coordinador;Nombre Completo;Documento;Sexo;Nivel;Telefono;Estado Inscripcion;Fecha Revision');

    // Ordenar: Municipio asc -> Bosque asc -> Nombre asc
    final listaOrdenada = List<InscripcionModel>.from(inscripciones)
      ..sort((a, b) {
        final munComp = a.municipio.compareTo(b.municipio);
        if (munComp != 0) return munComp;

        final bNameA = nombresBosques[a.bosqueId] ?? a.bosqueId;
        final bNameB = nombresBosques[b.bosqueId] ?? b.bosqueId;
        final bosqueComp = bNameA.compareTo(bNameB);
        if (bosqueComp != 0) return bosqueComp;

        return a.nombre.compareTo(b.nombre);
      });

    for (final ins in listaOrdenada) {
      final bName = nombresBosques[ins.bosqueId] ?? ins.bosqueId;
      final coord = nombresCoordinadores[ins.bosqueId] ?? 'No asignado';
      final fechaRevision = ins.revisadoAt != null
          ? ins.revisadoAt!.toLocal().toString().split(' ').first
          : 'Pendiente';

      final cleanNombre = ins.nombre.replaceAll(';', ',');
      final cleanDoc = ins.documentoId.replaceAll(';', ',');
      final cleanTel = ins.telefono.replaceAll(';', ',');

      buffer.writeln(
        '${ins.municipio};$bName;$coord;$cleanNombre;$cleanDoc;${ins.sexo};${ins.nivel};$cleanTel;${ins.estado.toUpperCase()};$fechaRevision',
      );
    }

    // Guardar archivo temporal y compartir
    final tempDir = await getTemporaryDirectory();
    final safeTitle = evento.titulo.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final filePath = '${tempDir.path}/reporte_inscritos_$safeTitle.csv';
    final file = File(filePath);

    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: 'Reporte de Inscritos: ${evento.titulo}',
      subject: 'Inscritos ${evento.titulo}',
    );
  }
}
