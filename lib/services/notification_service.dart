import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'firestore_service.dart';
import 'messaging_service.dart';

/// Servicio de alto nivel para notificaciones internas (Firestore) y push (FCM).
/// Utiliza [MessagingService] para push y [FirestoreService] para persistencia.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  // ── Suscripciones a topics de bosque ─────────────────────────────────

  /// Suscribir al usuario al topic FCM de su bosque
  Future<void> subscribeToBosque(String bosqueId) async {
    await MessagingService.subscribeToTopic('bosque_$bosqueId');
  }

  /// Desuscribir del topic FCM de un bosque
  Future<void> unsubscribeFromBosque(String bosqueId) async {
    await MessagingService.unsubscribeFromTopic('bosque_$bosqueId');
  }

  // ── Guardar notificación en Firestore ────────────────────────────────

  /// Guardar notificación para un usuario específico
  Future<void> saveNotificationForUser({
    required String userId,
    required String type,
    required String title,
    required String body,
  }) async {
    final notification = NotificationModel(
      id: '',
      type: type,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      read: false,
    );
    await _firestoreService.addNotification(userId, notification);
  }

  /// Guardar notificación para todos los miembros de un bosque
  Future<void> notifyBosqueMembers({
    required String bosqueId,
    required String bosqueNombre,
    required String type,
    required String title,
    required String body,
    String? excludeUserId, // No notificar al autor
  }) async {
    try {
      // Obtener todos los miembros del bosque
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('bosques')
          .doc(bosqueId)
          .collection('miembros')
          .get();

      for (final memberDoc in membersSnapshot.docs) {
        final memberId = memberDoc.id;
        if (memberId == excludeUserId) continue;

        await saveNotificationForUser(
          userId: memberId,
          type: type,
          title: title,
          body: body,
        );
      }

      // También notificar al líder/coordinador del bosque si no es el autor
      final bosqueDoc = await FirebaseFirestore.instance
          .collection('bosques')
          .doc(bosqueId)
          .get();
      final liderId = bosqueDoc.data()?['liderId'] as String?;
      if (liderId != null && liderId != excludeUserId) {
        // Verificar si ya se le notificó como miembro
        final alreadyNotified = membersSnapshot.docs.any((d) => d.id == liderId);
        if (!alreadyNotified) {
          await saveNotificationForUser(
            userId: liderId,
            type: type,
            title: title,
            body: body,
          );
        }
      }
    } catch (e) {
      debugPrint('Error notificando miembros del bosque: $e');
    }
  }

  // ── Marcar como leída ────────────────────────────────────────────────

  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestoreService.markNotificationAsRead(userId, notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _firestoreService.markAllNotificationsAsRead(userId);
  }

  // ── Streams ──────────────────────────────────────────────────────────

  Stream<QuerySnapshot> streamNotifications(String userId) {
    return _firestoreService.streamNotifications(userId);
  }

  Stream<int> streamUnreadCount(String userId) {
    return _firestoreService.streamUnreadNotificationCount(userId);
  }
}
