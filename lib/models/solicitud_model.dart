import 'package:cloud_firestore/cloud_firestore.dart';

class SolicitudModel {
  final String id;
  final String bosqueId;
  final String usuarioId;
  final String estado;
  final DateTime createdAt;
  final DateTime? approvedAt;

  SolicitudModel({
    required this.id,
    required this.bosqueId,
    required this.usuarioId,
    this.estado = 'pendiente',
    required this.createdAt,
    this.approvedAt,
  });

  factory SolicitudModel.fromJson(Map<String, dynamic> json) {
    return SolicitudModel(
      id: json['id'] as String,
      bosqueId: json['bosqueId'] as String,
      usuarioId: json['usuarioId'] as String,
      estado: json['estado'] as String? ?? 'pendiente',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.parse(json['createdAt'] as String),
      approvedAt: json['approvedAt'] != null ? (json['approvedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bosqueId': bosqueId,
      'usuarioId': usuarioId,
      'estado': estado,
      'createdAt': createdAt,
      'approvedAt': approvedAt,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bosqueId': bosqueId,
      'usuarioId': usuarioId,
      'estado': estado,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }
}
