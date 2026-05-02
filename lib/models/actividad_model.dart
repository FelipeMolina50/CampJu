import 'package:cloud_firestore/cloud_firestore.dart';

class ActividadModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime date;
  final String type; // 'campamento', 'evento', etc.

  ActividadModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.date,
    required this.type,
  });

  factory ActividadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActividadModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'date': Timestamp.fromDate(date),
      'type': type,
    };
  }
}
