import '../models/curso_model.dart';
import '../models/leccion_model.dart';
import 'firestore_service.dart';

class CursoService {
  final FirestoreService _firestoreService = FirestoreService();
  final String _cursoCollection = 'cursos';
  final String _leccionCollection = 'lecciones';

  Future<List<CursoModel>> obtenerCursos() async {
    try {
      final snapshot =
          await _firestoreService.getCollectionDocuments(_cursoCollection);
      return snapshot.docs
          .map((doc) =>
              CursoModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<CursoModel?> obtenerCurso(String cursoId) async {
    try {
      final doc =
          await _firestoreService.getDocument(_cursoCollection, cursoId);
      if (!doc.exists) return null;
      return CursoModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LeccionModel>> obtenerLecciones(String cursoId) async {
    try {
      final snapshot = await _firestoreService.getCollectionDocuments(
        _leccionCollection,
        where: (ref) =>
            ref.where('cursoId', isEqualTo: cursoId)
                .orderBy('orden', descending: false),
      );
      return snapshot.docs
          .map((doc) =>
              LeccionModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> marcarLeccionCompletada(String leccionId) async {
    try {
      await _firestoreService.updateDocument(
        _leccionCollection,
        leccionId,
        {'completada': true},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> actualizarProgresoCurso(
    String cursoId,
    int leccionesCompletadas,
    double progreso,
  ) async {
    try {
      await _firestoreService.updateDocument(
        _cursoCollection,
        cursoId,
        {
          'leccionesCompletadas': leccionesCompletadas,
          'progreso': progreso,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
