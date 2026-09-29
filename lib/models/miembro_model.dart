
class MiembroModel {
  final String id;
  final String bosqueId;
  final String usuarioId;
  final String nombre;
  final String rol;
  final DateTime fechaIngreso;
  final DateTime updatedAt;
  final DateTime? lastReadAt;

  MiembroModel({
    required this.id,
    required this.bosqueId,
    required this.usuarioId,
    required this.nombre,
    required this.rol,
    required this.fechaIngreso,
    required this.updatedAt,
    this.lastReadAt,
  });

  factory MiembroModel.fromJson(Map<String, dynamic> json) {
    return MiembroModel(
      id: json['id'] as String,
      bosqueId: json['bosqueId'] as String,
      usuarioId: json['usuarioId'] as String,
      nombre: json['nombre'] as String,
      rol: json['rol'] as String,
      fechaIngreso: DateTime.parse(json['fechaIngreso'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastReadAt: json['lastReadAt'] != null ? DateTime.parse(json['lastReadAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bosqueId': bosqueId,
      'usuarioId': usuarioId,
      'nombre': nombre,
      'rol': rol,
      'fechaIngreso': fechaIngreso.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (lastReadAt != null) 'lastReadAt': lastReadAt!.toIso8601String(),
    };
  }
}
