import 'package:cloud_firestore/cloud_firestore.dart';

enum SolicitudStatus { pendiente, aceptada, rechazada }

class SolicitudModel {
  final String id;
  final String userId;
  final String userName;
  final String bosqueId;
  final String bosqueNombre;
  final SolicitudStatus status;
  final DateTime createdAt;

  SolicitudModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.bosqueId,
    required this.bosqueNombre,
    this.status = SolicitudStatus.pendiente,
    required this.createdAt,
  });

  factory SolicitudModel.fromJson(Map<String, dynamic> json) {
    return SolicitudModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? 'Usuario',
      bosqueId: json['bosqueId'] as String,
      bosqueNombre: json['bosqueNombre'] as String? ?? 'Bosque',
      status: SolicitudStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'pendiente'),
        orElse: () => SolicitudStatus.pendiente,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'bosqueId': bosqueId,
      'bosqueNombre': bosqueNombre,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
