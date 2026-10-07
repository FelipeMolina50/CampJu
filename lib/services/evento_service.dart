import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento_model.dart';
import '../models/inscripcion_model.dart';
import 'notification_service.dart';

class EventoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _eventosCollection = 'eventos';
  final String _inscripcionesCollection = 'inscripciones';
  final NotificationService _notificationService = NotificationService();

  Future<void> crearEvento(EventoModel evento) async {
    final docRef = await _firestore.collection(_eventosCollection).add(evento.toMap());

    // Notificar a bosques destinatarios y agregar mensaje del sistema en el chat
    for (final bId in evento.bosquesIds) {
      _firestore.collection('bosques').doc(bId).collection('mensajes').add({
        'senderId': 'system',
        'senderName': 'CampJu Sistema',
        'message': 'Nuevo evento programado: ${evento.titulo} en ${evento.lugar}',
        'timestamp': FieldValue.serverTimestamp(),
        'tipo': 'sistema_evento',
        'eventoId': docRef.id,
      }).then((_) {}, onError: (_) {});

      _notificationService.notifyBosqueMembers(
        bosqueId: bId,
        bosqueNombre: '',
        type: 'evento',
        title: 'Nuevo Evento: ${evento.titulo}',
        body: 'Se ha programado una actividad en ${evento.lugar}. ¡Inscribete!',
      ).catchError((_) {});
    }
  }

  Future<void> eliminarEvento(String eventoId) async {
    await _firestore.collection(_eventosCollection).doc(eventoId).delete();
  }

  Future<EventoModel?> getEventoById(String id) async {
    final doc = await _firestore.collection(_eventosCollection).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return EventoModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Stream reactivo de eventos según las reglas del plan 5.4:
  /// Se muestran los eventos dirigidos al bosque del usuario + departamentales y nacionales (abiertos a todos)
  Stream<List<EventoModel>> streamEventosUsuario({String? bosqueId}) {
    return _firestore
        .collection(_eventosCollection)
        .orderBy('fechaInicio', descending: false)
        .snapshots()
        .map((snapshot) {
      final todos = snapshot.docs.map((d) => EventoModel.fromMap(d.data(), d.id)).toList();
      return todos.where((ev) {
        if (ev.tipo == 'departamental' || ev.tipo == 'nacional') return true;
        if (bosqueId != null && ev.bosquesIds.contains(bosqueId)) return true;
        if (ev.bosquesIds.isEmpty && ev.tipo == 'actividad') return true;
        return false;
      }).toList();
    });
  }

  /// Stream de inscripción de un usuario específico para un evento determinado
  Stream<InscripcionModel?> streamMiInscripcion(String eventoId, String uid) {
    final docId = '${eventoId}_$uid';
    return _firestore.collection(_inscripcionesCollection).doc(docId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return InscripcionModel.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  /// Crear o actualizar inscripción en borrador / pendiente
  Future<void> enviarInscripcion(InscripcionModel inscripcion) async {
    await _firestore.collection(_inscripcionesCollection).doc(inscripcion.id).set(
          inscripcion.toMap(),
          SetOptions(merge: true),
        );

    if (inscripcion.estado == 'pendiente') {
      _firestore.collection('bosques').doc(inscripcion.bosqueId).get().then((bDoc) {
        final liderId = bDoc.data()?['liderId'] as String?;
        if (liderId != null && liderId.isNotEmpty) {
          _notificationService.saveNotificationForUser(
            userId: liderId,
            type: 'evento',
            title: 'Nueva inscripcion pendiente',
            body: '${inscripcion.nombre} ha enviado su inscripcion para revision.',
          );
        }
      }).catchError((_) {});
    }
  }

  /// Revisión de documentos por parte del coordinador o Super Admin
  Future<void> revisarDocumento({
    required String inscripcionId,
    required String docReqId,
    required String estado, // 'ok' o 'rechazado'
    String? nota,
    required String revisorId,
  }) async {
    final ref = _firestore.collection(_inscripcionesCollection).doc(inscripcionId);
    await ref.update({
      'documentos.$docReqId.estado': estado,
      if (nota != null) 'documentos.$docReqId.nota': nota,
      'revisadoPor': revisorId,
      'revisadoAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (estado == 'rechazado') {
      ref.get().then((doc) {
        final uid = doc.data()?['uid'] as String?;
        if (uid != null) {
          _notificationService.saveNotificationForUser(
            userId: uid,
            type: 'evento',
            title: 'Documento observado',
            body: 'Un documento de tu inscripcion requiere correccion${nota != null ? ': $nota' : '.'}',
          );
        }
      }).catchError((_) {});
    }
  }

  /// Aprobar inscripción en transacción (valida cupo e incrementa aprobadosCount)
  Future<void> aprobarInscripcion({
    required String inscripcionId,
    required String eventoId,
    required String revisorId,
  }) async {
    final inscRef = _firestore.collection(_inscripcionesCollection).doc(inscripcionId);
    final eventoRef = _firestore.collection(_eventosCollection).doc(eventoId);
    String? campistaUid;

    await _firestore.runTransaction((tx) async {
      final evDoc = await tx.get(eventoRef);
      if (!evDoc.exists) throw Exception('El evento no existe.');

      final evData = evDoc.data()!;
      final cupoTotal = evData['cupoTotal'] as int?;
      final aprobadosCount = evData['aprobadosCount'] as int? ?? 0;

      if (cupoTotal != null && aprobadosCount >= cupoTotal) {
        throw Exception('El evento ha alcanzado el limite maximo de cupos.');
      }

      final inscDoc = await tx.get(inscRef);
      if (inscDoc.exists) {
        campistaUid = inscDoc.data()?['uid'] as String?;
      }

      tx.update(inscRef, {
        'estado': 'aprobada',
        'revisadoPor': revisorId,
        'revisadoAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(eventoRef, {
        'aprobadosCount': aprobadosCount + 1,
      });
    });

    if (campistaUid != null) {
      _notificationService.saveNotificationForUser(
        userId: campistaUid!,
        type: 'evento',
        title: 'Inscripcion aprobada',
        body: 'Tu inscripcion al evento ha sido aprobada. ¡Ya aparece en tu Agenda!',
      ).catchError((_) {});
    }
  }

  /// Rechazar inscripción con motivo
  Future<void> rechazarInscripcion({
    required String inscripcionId,
    required String motivo,
    required String revisorId,
  }) async {
    final ref = _firestore.collection(_inscripcionesCollection).doc(inscripcionId);
    await ref.update({
      'estado': 'rechazada',
      'motivo': motivo,
      'revisadoPor': revisorId,
      'revisadoAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    ref.get().then((doc) {
      final uid = doc.data()?['uid'] as String?;
      if (uid != null) {
        _notificationService.saveNotificationForUser(
          userId: uid,
          type: 'evento',
          title: 'Inscripcion rechazada',
          body: 'Tu inscripcion fue rechazada. Motivo: $motivo',
        );
      }
    }).catchError((_) {});
  }

  /// Stream de inscripciones para el coordinador de un bosque
  Stream<List<InscripcionModel>> streamInscripcionesBosque(String bosqueId, {String? eventoId}) {
    Query query = _firestore.collection(_inscripcionesCollection).where('bosqueId', isEqualTo: bosqueId);
    if (eventoId != null) {
      query = query.where('eventoId', isEqualTo: eventoId);
    }
    return query.snapshots().map((snap) =>
        snap.docs.map((d) => InscripcionModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList());
  }

  /// Stream de todos los inscritos para el Super Admin
  Stream<List<InscripcionModel>> streamInscripcionesEvento(String eventoId) {
    return _firestore
        .collection(_inscripcionesCollection)
        .where('eventoId', isEqualTo: eventoId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => InscripcionModel.fromMap(d.data(), d.id)).toList());
  }
}
