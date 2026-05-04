import 'package:cloud_firestore/cloud_firestore.dart';

class EventoModel {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final String lugar;
  final String tipo;
  final String? imagenUrl;

  EventoModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.lugar,
    required this.tipo,
    this.imagenUrl,
  });

  factory EventoModel.fromJson(Map<String, dynamic> json) {
    return EventoModel(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      fecha: (json['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lugar: json['lugar'] as String,
      tipo: json['tipo'] as String,
      imagenUrl: json['imagenUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha': fecha,
      'lugar': lugar,
      'tipo': tipo,
      'imagenUrl': imagenUrl,
    };
  }
}
