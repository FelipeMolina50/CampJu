import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).add(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(docId)
          .set(data, SetOptions(merge: merge));
    } catch (e) {
      rethrow;
    }
  }

  Future<DocumentSnapshot> getDocument(
    String collection,
    String docId,
  ) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      rethrow;
    }
  }

  Future<QuerySnapshot> getCollectionDocuments(
    String collection, {
    Query Function(CollectionReference)? where,
  }) async {
    try {
      CollectionReference collectionRef = _firestore.collection(collection);
      if (where != null) {
        return await where(collectionRef).get();
      }
      return await collectionRef.get();
    } catch (e) {
      rethrow;
    }
  }

  Stream<QuerySnapshot> streamCollectionDocuments(
    String collection, {
    Query Function(CollectionReference)? where,
  }) {
    try {
      CollectionReference collectionRef = _firestore.collection(collection);
      if (where != null) {
        return where(collectionRef).snapshots();
      }
      return collectionRef.snapshots();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection(collection)
          .doc(docId)
          .update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDocument(
    String collection,
    String docId,
  ) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // ── Notificaciones ──────────────────────────────────────────────────

  /// Agregar una notificación a la sub-colección del usuario
  Future<void> addNotification(String userId, NotificationModel notification) async {
    try {
      await _firestore
          .collection('notificaciones')
          .doc(userId)
          .collection('items')
          .add(notification.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Marcar una notificación como leída
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('notificaciones')
          .doc(userId)
          .collection('items')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      rethrow;
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notificaciones')
          .doc(userId)
          .collection('items')
          .where('read', isEqualTo: false)
          .get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream de notificaciones del usuario (ordenadas por fecha desc)
  Stream<QuerySnapshot> streamNotifications(String userId) {
    return _firestore
        .collection('notificaciones')
        .doc(userId)
        .collection('items')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Stream del conteo de notificaciones no leídas
  Stream<int> streamUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notificaciones')
        .doc(userId)
        .collection('items')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
