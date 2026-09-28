import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentoRequerido {
  final String id;
  final String nombre;
  final bool obligatorio;

  DocumentoRequerido({
    required this.id,
    required this.nombre,
    this.obligatorio = true,
  });

  factory DocumentoRequerido.fromMap(Map<String, dynamic> map) {
    return DocumentoRequerido(
      id: map['id'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      obligatorio: map['obligatorio'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'obligatorio': obligatorio,
    };
  }
}

class EventoModel {
  final String id;
  final String titulo;
  final String descripcion;
  final String lugar;
  final String municipioSede;
  final String tipo; // 'actividad', 'campista_dia', 'municipal', 'interzonal', 'departamental', 'nacional'
  final List<String> bosquesIds; // Destinatarios específicos. Vacío en departamental/nacional = todos
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool requiereInscripcion;
  final List<DocumentoRequerido> documentosRequeridos;
  final DateTime? fechaLimiteInscripcion;
  final DateTime? fechaLimiteAprobacion;
  final int? cupoTotal;
  final int? cupoPorBosque;
  final int aprobadosCount;
  final String estado; // 'abierto', 'cerrado', 'cancelado'
  final String creadoPor;
  final String creadorRol;
  final DateTime createdAt;

  EventoModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.lugar,
    this.municipioSede = '',
    required this.tipo,
    this.bosquesIds = const [],
    required this.fechaInicio,
    required this.fechaFin,
    this.requiereInscripcion = false,
    this.documentosRequeridos = const [],
    this.fechaLimiteInscripcion,
    this.fechaLimiteAprobacion,
    this.cupoTotal,
    this.cupoPorBosque,
    this.aprobadosCount = 0,
    this.estado = 'abierto',
    required this.creadoPor,
    this.creadorRol = 'coordinador',
    required this.createdAt,
  });

  factory EventoModel.fromMap(Map<String, dynamic> map, String docId) {
    return EventoModel(
      id: docId,
      titulo: map['titulo'] as String? ?? 'Evento',
      descripcion: map['descripcion'] as String? ?? '',
      lugar: map['lugar'] as String? ?? 'Por definir',
      municipioSede: map['municipioSede'] as String? ?? '',
      tipo: map['tipo'] as String? ?? 'actividad',
      bosquesIds: List<String>.from(map['bosquesIds'] ?? []),
      fechaInicio: (map['fechaInicio'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaFin: (map['fechaFin'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 2)),
      requiereInscripcion: map['requiereInscripcion'] as bool? ?? false,
      documentosRequeridos: (map['documentosRequeridos'] as List<dynamic>?)
              ?.map((d) => DocumentoRequerido.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      fechaLimiteInscripcion: (map['fechaLimiteInscripcion'] as Timestamp?)?.toDate(),
      fechaLimiteAprobacion: (map['fechaLimiteAprobacion'] as Timestamp?)?.toDate(),
      cupoTotal: map['cupoTotal'] as int?,
      cupoPorBosque: map['cupoPorBosque'] as int?,
      aprobadosCount: map['aprobadosCount'] as int? ?? 0,
      estado: map['estado'] as String? ?? 'abierto',
      creadoPor: map['creadoPor'] as String? ?? '',
      creadorRol: map['creadorRol'] as String? ?? 'coordinador',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'lugar': lugar,
      'municipioSede': municipioSede,
      'tipo': tipo,
      'bosquesIds': bosquesIds,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'requiereInscripcion': requiereInscripcion,
      'documentosRequeridos': documentosRequeridos.map((d) => d.toMap()).toList(),
      if (fechaLimiteInscripcion != null) 'fechaLimiteInscripcion': Timestamp.fromDate(fechaLimiteInscripcion!),
      if (fechaLimiteAprobacion != null) 'fechaLimiteAprobacion': Timestamp.fromDate(fechaLimiteAprobacion!),
      'cupoTotal': cupoTotal,
      'cupoPorBosque': cupoPorBosque,
      'aprobadosCount': aprobadosCount,
      'estado': estado,
      'creadoPor': creadoPor,
      'creadorRol': creadorRol,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
