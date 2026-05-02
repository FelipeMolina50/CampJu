import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento_model.dart';
import '../models/actividad_model.dart';

class EventoService {
  static CollectionReference eventosRef(String bosqueId) {
    return FirebaseFirestore.instance
        .collection('bosques')
        .doc(bosqueId)
        .collection('eventos');
  }

  static Future<void> createEvento(String bosqueId, EventoModel evento) async {
    await eventosRef(bosqueId).add(evento.toJson());
  }

  static Stream<List<EventoModel>> getEventosStream(String bosqueId) {
    return eventosRef(bosqueId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventoModel.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>
            }))
            .toList());
  }

  static Future<void> updateEvento(String bosqueId, String eventoId, EventoModel evento) async {
    await eventosRef(bosqueId).doc(eventoId).update(evento.toJson());
  }

  static Future<void> deleteEvento(String bosqueId, String eventoId) async {
    await eventosRef(bosqueId).doc(eventoId).delete();
  }

  // Activities related to events
  static Stream<List<ActividadModel>> getActividadesStream(String eventoId) {
    return FirebaseFirestore.instance
        .collection('eventos')
        .doc(eventoId)
        .collection('actividades')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActividadModel.fromFirestore(doc))
            .toList());
  }
}
