import 'package:cloud_firestore/cloud_firestore.dart';

class BosqueModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String zona;
  final String liderId;
  final String? fotoUrl;
  final int miembros;
  final DateTime createdAt;
  final DateTime updatedAt;

  BosqueModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.zona,
    required this.liderId,
    this.fotoUrl,
    this.miembros = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getters for screens compatibility
  String get name => nombre;
  String get imageUrl => fotoUrl ?? '';
  int get miembrosCount => miembros;
  String get lider => liderId;

  factory BosqueModel.fromJson(Map<String, dynamic> json) {
    return BosqueModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      zona: json['zona'] as String,
      liderId: json['liderId'] as String,
      fotoUrl: json['fotoUrl'] as String?,
      miembros: json['miembros'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.parse(json['createdAt'] as String),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.parse(json['updatedAt'] as String),
    );
  }

  factory BosqueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BosqueModel.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'zona': zona,
      'liderId': liderId,
      'fotoUrl': fotoUrl,
      'miembros': miembros,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'zona': zona,
      'liderId': liderId,
      'fotoUrl': fotoUrl,
      'miembros': miembros,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
