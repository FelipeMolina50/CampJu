import 'package:cloud_firestore/cloud_firestore.dart';

class ComentarioModel {
  final String id;
  final String publicacionId;
  final String usuarioId;
  final String usuarioNombre;
  final String texto;
  final DateTime createdAt;

  ComentarioModel({
    required this.id,
    required this.publicacionId,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.texto,
    required this.createdAt,
  });

  factory ComentarioModel.fromMap(Map<String, dynamic> map, String docId) {
    return ComentarioModel(
      id: docId,
      publicacionId: map['publicacionId'] ?? '',
      usuarioId: map['usuarioId'] ?? '',
      usuarioNombre: map['usuarioNombre'] ?? 'Usuario',
      texto: map['texto'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'publicacionId': publicacionId,
      'usuarioId': usuarioId,
      'usuarioNombre': usuarioNombre,
      'texto': texto,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

