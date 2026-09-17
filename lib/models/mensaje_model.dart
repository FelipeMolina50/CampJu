import 'package:cloud_firestore/cloud_firestore.dart';

class MensajeModel {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String tipo; // 'texto' | 'imagen' | 'archivo'
  final String? imageUrl;
  final String? fileName;

  MensajeModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.tipo = 'texto',
    this.imageUrl,
    this.fileName,
  });

  factory MensajeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MensajeModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      tipo: data['tipo'] ?? 'texto',
      imageUrl: data['imageUrl'],
      fileName: data['fileName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'tipo': tipo,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (fileName != null) 'fileName': fileName,
    };
  }
}
