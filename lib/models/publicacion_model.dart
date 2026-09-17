import 'package:cloud_firestore/cloud_firestore.dart';

class PublicacionModel {
  final String id;
  final String bosqueId;
  final String coordinadorId;
  final String coordinadorNombre;
  final String titulo;
  final String? texto;
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;

  PublicacionModel({
    required this.id,
    required this.bosqueId,
    required this.coordinadorId,
    required this.coordinadorNombre,
    required this.titulo,
    this.texto,
    required this.mediaUrls,
    required this.mediaTypes,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  factory PublicacionModel.fromMap(Map<String, dynamic> map, String docId) {
    return PublicacionModel(
      id: docId,
      bosqueId: map['bosqueId'] ?? '',
      coordinadorId: map['coordinadorId'] ?? '',
      coordinadorNombre: map['coordinadorNombre'] ?? 'Coordinador',
      titulo: map['titulo'] ?? '',
      texto: map['texto'],
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      mediaTypes: List<String>.from(map['mediaTypes'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bosqueId': bosqueId,
      'coordinadorId': coordinadorId,
      'coordinadorNombre': coordinadorNombre,
      'titulo': titulo,
      'texto': texto,
      'mediaUrls': mediaUrls,
      'mediaTypes': mediaTypes,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
    };
  }
}

