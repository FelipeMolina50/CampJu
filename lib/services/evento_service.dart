import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento_model.dart';

class EventoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'eventos';

  Future<void> crearEvento(EventoModel evento) async {
    await _firestore.collection(_collection).add(evento.toMap());
  }

  Future<void> eliminarEvento(String eventoId) async {
    await _firestore.collection(_collection).doc(eventoId).delete();
  }

  /// Stream reactivo de eventos visibles para el usuario (globales + los de su bosque)
  Stream<List<EventoModel>> streamEventosUsuario({String? bosqueId}) {
    return _firestore
        .collection(_collection)
        .orderBy('fechaInicio', descending: false)
        .snapshots()
        .map((snapshot) {
          final todos = snapshot.docs.map((d) => EventoModel.fromMap(d.data(), d.id)).toList();
          return todos.where((ev) {
            if (ev.scope == 'global') return true;
            if (bosqueId != null && ev.bosqueId == bosqueId) return true;
            return false;
          }).toList();
        });
  }
}
