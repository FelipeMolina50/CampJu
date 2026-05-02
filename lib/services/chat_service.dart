import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mensaje_model.dart';

class ChatService {
  // Get messages stream for bosque chat
  static Stream<List<MensajeModel>> getMessagesStream(String bosqueId) {
    return FirebaseFirestore.instance
        .collection('bosques')
        .doc(bosqueId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MensajeModel.fromFirestore(doc))
            .toList());
  }

  // Send new message to bosque chat
  static Future<void> sendMessage(String bosqueId, MensajeModel mensaje) async {
    await FirebaseFirestore.instance
        .collection('bosques')
        .doc(bosqueId)
        .collection('messages')
        .add(mensaje.toFirestore());
  }

  // Mark message as read
  static Future<void> markAsRead(String bosqueId, String messageId) async {
    await FirebaseFirestore.instance
        .collection('bosques')
        .doc(bosqueId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }
}
