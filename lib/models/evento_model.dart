import 'package:cloud_firestore/cloud_firestore.dart';

class EventoModel {
  final String id;
  final String titulo;
  final String descripcion;
  final String lugar;
  final String responsable;
  final String tipo; // 'campamento', 'reunion', 'ceremonia', 'capacitacion', 'otro'
  final String scope; // 'global', 'bosque'
  final String? bosqueId;
  final String? bosqueNombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String creadoPor;
  final DateTime createdAt;

  EventoModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.lugar,
    required this.responsable,
    required this.tipo,
    required this.scope,
    this.bosqueId,
    this.bosqueNombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.creadoPor,
    required this.createdAt,
  });

  factory EventoModel.fromMap(Map<String, dynamic> map, String docId) {
    return EventoModel(
      id: docId,
      titulo: map['titulo'] as String? ?? 'Evento',
      descripcion: map['descripcion'] as String? ?? '',
      lugar: map['lugar'] as String? ?? 'Por definir',
      responsable: map['responsable'] as String? ?? 'Coordinacion',
      tipo: map['tipo'] as String? ?? 'otro',
      scope: map['scope'] as String? ?? 'global',
      bosqueId: map['bosqueId'] as String?,
      bosqueNombre: map['bosqueNombre'] as String?,
      fechaInicio: (map['fechaInicio'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaFin: (map['fechaFin'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 2)),
      creadoPor: map['creadoPor'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'lugar': lugar,
      'responsable': responsable,
      'tipo': tipo,
      'scope': scope,
      'bosqueId': bosqueId,
      'bosqueNombre': bosqueNombre,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'creadoPor': creadoPor,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
