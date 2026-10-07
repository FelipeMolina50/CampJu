import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentoInscripcion {
  final String path;
  final String estado; // 'pendiente', 'ok', 'rechazado'
  final String? nota;

  DocumentoInscripcion({
    required this.path,
    this.estado = 'pendiente',
    this.nota,
  });

  factory DocumentoInscripcion.fromMap(Map<String, dynamic> map) {
    return DocumentoInscripcion(
      path: map['path'] as String? ?? '',
      estado: map['estado'] as String? ?? 'pendiente',
      nota: map['nota'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'estado': estado,
      if (nota != null) 'nota': nota,
    };
  }
}

class InscripcionModel {
  final String id; // eventoId_uid
  final String eventoId;
  final String uid;
  final String bosqueId;
  final String nombre;
  final String documentoId;
  final String municipio;
  final String sexo;
  final String nivel;
  final String telefono;
  final String estado; // 'borrador', 'pendiente', 'observada', 'aprobada', 'rechazada', 'cancelada'
  final Map<String, DocumentoInscripcion> documentos;
  final String? motivo;
  final String? revisadoPor;
  final DateTime? revisadoAt;
  final DateTime? autorizacionDatosAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  InscripcionModel({
    required this.id,
    required this.eventoId,
    required this.uid,
    required this.bosqueId,
    required this.nombre,
    this.documentoId = '',
    this.municipio = '',
    this.sexo = '',
    this.nivel = '',
    this.telefono = '',
    this.estado = 'borrador',
    this.documentos = const {},
    this.motivo,
    this.revisadoPor,
    this.revisadoAt,
    this.autorizacionDatosAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InscripcionModel.fromMap(Map<String, dynamic> map, String docId) {
    final docsRaw = map['documentos'] as Map<String, dynamic>? ?? {};
    final docsMap = docsRaw.map(
      (key, value) => MapEntry(key, DocumentoInscripcion.fromMap(value as Map<String, dynamic>)),
    );

    return InscripcionModel(
      id: docId,
      eventoId: map['eventoId'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      bosqueId: map['bosqueId'] as String? ?? '',
      nombre: map['nombre'] as String? ?? 'Campista',
      documentoId: map['documentoId'] as String? ?? '',
      municipio: map['municipio'] as String? ?? '',
      sexo: map['sexo'] as String? ?? '',
      nivel: map['nivel'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
      estado: map['estado'] as String? ?? 'borrador',
      documentos: docsMap,
      motivo: map['motivo'] as String?,
      revisadoPor: map['revisadoPor'] as String?,
      revisadoAt: (map['revisadoAt'] as Timestamp?)?.toDate(),
      autorizacionDatosAt: (map['autorizacionDatosAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventoId': eventoId,
      'uid': uid,
      'bosqueId': bosqueId,
      'nombre': nombre,
      'documentoId': documentoId,
      'municipio': municipio,
      'sexo': sexo,
      'nivel': nivel,
      'telefono': telefono,
      'estado': estado,
      'documentos': documentos.map((k, v) => MapEntry(k, v.toMap())),
      if (motivo != null) 'motivo': motivo,
      if (revisadoPor != null) 'revisadoPor': revisadoPor,
      if (revisadoAt != null) 'revisadoAt': Timestamp.fromDate(revisadoAt!),
      if (autorizacionDatosAt != null) 'autorizacionDatosAt': Timestamp.fromDate(autorizacionDatosAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
