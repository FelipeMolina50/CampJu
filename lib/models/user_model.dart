
enum UserRole { campista, coordinador, admin }

class UserModel {
  final String id;
  final String email;
  final bool emailVerified;
  final String name;
  final String apellidos;
  final String municipio;
  final DateTime fechaNacimiento;
  final String tipoDocumento;
  final String numeroDocumento;
  final String sexo;
  final String telefono;
  final String eps;
  final DateTime? fechaIngresoPrograma;
  final String rango;
  final bool esArbolMayor;
  final String? bosqueId;
  final DateTime? fechaIngresoBosque;
  final bool perfilCompleto;
  final String? nombreAcudiente;
  final String? telefonoAcudiente;
  final String? photoUrl;
  final UserRole role;
  final String? genero;
  final String? orientacionSexual;
  final String? discapacidad;
  final String? grupoPoblacional;
  final bool? esVictimaConflicto;
  final String? zonaDondeVive;
  final String? nivelEducativo;
  final String? ocupacion;
  final String? numeroResolucion;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.emailVerified = false,
    required this.name,
    required this.apellidos,
    required this.municipio,
    required this.fechaNacimiento,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.sexo,
    required this.telefono,
    required this.eps,
    this.fechaIngresoPrograma,
    this.rango = 'aspirante',
    this.esArbolMayor = false,
    this.bosqueId,
    this.fechaIngresoBosque,
    this.perfilCompleto = false,
    this.nombreAcudiente,
    this.telefonoAcudiente,
    this.photoUrl,
    this.role = UserRole.campista,
    this.genero,
    this.orientacionSexual,
    this.discapacidad,
    this.grupoPoblacional,
    this.esVictimaConflicto,
    this.zonaDondeVive,
    this.nivelEducativo,
    this.ocupacion,
    this.numeroResolucion,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      emailVerified: json['emailVerified'] as bool? ?? false,
      name: json['name'] as String,
      apellidos: json['apellidos'] as String,
      municipio: json['municipio'] as String,
      fechaNacimiento: DateTime.parse(json['fechaNacimiento'] as String),
      tipoDocumento: json['tipoDocumento'] as String,
      numeroDocumento: json['numeroDocumento'] as String,
      sexo: json['sexo'] as String,
      telefono: json['telefono'] as String,
      eps: json['eps'] as String,
      fechaIngresoPrograma: json['fechaIngresoPrograma'] != null
          ? DateTime.parse(json['fechaIngresoPrograma'] as String)
          : null,
      rango: json['rango'] as String? ?? 'aspirante',
      esArbolMayor: json['esArbolMayor'] as bool? ?? false,
      bosqueId: json['bosqueId'] as String?,
      fechaIngresoBosque: json['fechaIngresoBosque'] != null
          ? DateTime.parse(json['fechaIngresoBosque'] as String)
          : null,
      perfilCompleto: json['perfilCompleto'] as bool? ?? false,
      nombreAcudiente: json['nombreAcudiente'] as String?,
      telefonoAcudiente: json['telefonoAcudiente'] as String?,
      photoUrl: json['photoUrl'] as String?,
      role: UserRole.values[json['role'] as int? ?? 0],
      genero: json['genero'] as String?,
      orientacionSexual: json['orientacionSexual'] as String?,
      discapacidad: json['discapacidad'] as String?,
      grupoPoblacional: json['grupoPoblacional'] as String?,
      esVictimaConflicto: json['esVictimaConflicto'] as bool?,
      zonaDondeVive: json['zonaDondeVive'] as String?,
      nivelEducativo: json['nivelEducativo'] as String?,
      ocupacion: json['ocupacion'] as String?,
      numeroResolucion: json['numeroResolucion'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    bool? emailVerified,
    String? name,
    String? apellidos,
    String? municipio,
    DateTime? fechaNacimiento,
    String? tipoDocumento,
    String? numeroDocumento,
    String? sexo,
    String? telefono,
    String? eps,
    DateTime? fechaIngresoPrograma,
    String? rango,
    bool? esArbolMayor,
    String? bosqueId,
    DateTime? fechaIngresoBosque,
    bool? perfilCompleto,
    String? nombreAcudiente,
    String? telefonoAcudiente,
    String? photoUrl,
    UserRole? role,
    String? genero,
    String? orientacionSexual,
    String? discapacidad,
    String? grupoPoblacional,
    bool? esVictimaConflicto,
    String? zonaDondeVive,
    String? nivelEducativo,
    String? ocupacion,
    String? numeroResolucion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      name: name ?? this.name,
      apellidos: apellidos ?? this.apellidos,
      municipio: municipio ?? this.municipio,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      sexo: sexo ?? this.sexo,
      telefono: telefono ?? this.telefono,
      eps: eps ?? this.eps,
      fechaIngresoPrograma: fechaIngresoPrograma ?? this.fechaIngresoPrograma,
      rango: rango ?? this.rango,
      esArbolMayor: esArbolMayor ?? this.esArbolMayor,
      bosqueId: bosqueId ?? this.bosqueId,
      fechaIngresoBosque: fechaIngresoBosque ?? this.fechaIngresoBosque,
      perfilCompleto: perfilCompleto ?? this.perfilCompleto,
      nombreAcudiente: nombreAcudiente ?? this.nombreAcudiente,
      telefonoAcudiente: telefonoAcudiente ?? this.telefonoAcudiente,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      genero: genero ?? this.genero,
      orientacionSexual: orientacionSexual ?? this.orientacionSexual,
      discapacidad: discapacidad ?? this.discapacidad,
      grupoPoblacional: grupoPoblacional ?? this.grupoPoblacional,
      esVictimaConflicto: esVictimaConflicto ?? this.esVictimaConflicto,
      zonaDondeVive: zonaDondeVive ?? this.zonaDondeVive,
      nivelEducativo: nivelEducativo ?? this.nivelEducativo,
      ocupacion: ocupacion ?? this.ocupacion,
      numeroResolucion: numeroResolucion ?? this.numeroResolucion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'emailVerified': emailVerified,
      'name': name,
      'apellidos': apellidos,
      'municipio': municipio,
      'fechaNacimiento': fechaNacimiento.toIso8601String(),
      'tipoDocumento': tipoDocumento,
      'numeroDocumento': numeroDocumento,
      'sexo': sexo,
      'telefono': telefono,
      'eps': eps,
      'fechaIngresoPrograma': fechaIngresoPrograma?.toIso8601String(),
      'rango': rango,
      'esArbolMayor': esArbolMayor,
      'bosqueId': bosqueId,
      'fechaIngresoBosque': fechaIngresoBosque?.toIso8601String(),
      'perfilCompleto': perfilCompleto,
      'nombreAcudiente': nombreAcudiente,
      'telefonoAcudiente': telefonoAcudiente,
      'photoUrl': photoUrl,
      'role': role.index,
      'genero': genero,
      'orientacionSexual': orientacionSexual,
      'discapacidad': discapacidad,
      'grupoPoblacional': grupoPoblacional,
      'esVictimaConflicto': esVictimaConflicto,
      'zonaDondeVive': zonaDondeVive,
      'nivelEducativo': nivelEducativo,
      'ocupacion': ocupacion,
      'numeroResolucion': numeroResolucion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get esMenorDeEdad {
    final edad = DateTime.now().difference(fechaNacimiento).inDays ~/ 365;
    return edad < 18;
  }

  String get rangoDisplay {
    switch (rango.toLowerCase()) {
      case 'aspirante':
        return 'Aspirante';
      case 'semilla':
        return 'Semilla';
      case 'raiz':
        return 'Raíz';
      case 'tallo':
        return 'Tallo';
      case 'hoja':
        return 'Hoja';
      case 'flor':
        return 'Flor';
      case 'fruto':
        return 'Fruto';
      default:
        return 'Aspirante';
    }
  }

  String get rangoEmoji {
    switch (rango.toLowerCase()) {
      case 'semilla':
        return '🌱';
      case 'raiz':
        return '🌿';
      case 'tallo':
        return '🪴';
      case 'hoja':
        return '🍃';
      case 'flor':
        return '🌸';
      case 'fruto':
        return '🍎';
      default:
        return '🌱';
    }
  }

  int get mesesEnPrograma {
    if (fechaIngresoPrograma == null) return 0;
    return DateTime.now().difference(fechaIngresoPrograma!).inDays ~/ 30;
  }
}
