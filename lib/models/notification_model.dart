import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type; // e.g., 'publicacion', 'mensaje', 'evento'
  final String title;
  final String body;
  final DateTime timestamp;
  final bool read;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.read,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, String documentId) {
    return NotificationModel(
      id: documentId,
      type: data['type'] as String? ?? 'generic',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      read: data['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
    };
  }
}

