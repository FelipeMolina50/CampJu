class FaqEntry {
  final String id;
  final String categoria;
  final List<String> keywords;
  final List<String> frases;
  final String respuesta;
  final List<String> roles;
  final String estado;
  final List<String> chips;
  final String? accion;
  final int prioridad;

  const FaqEntry({
    required this.id,
    required this.categoria,
    required this.keywords,
    this.frases = const [],
    required this.respuesta,
    this.roles = const ['*'],
    this.estado = 'disponible',
    this.chips = const [],
    this.accion,
    this.prioridad = 0,
  });

  factory FaqEntry.fromJson(Map<String, dynamic> j) => FaqEntry(
        id: j['id'] as String,
        categoria: j['categoria'] as String? ?? 'general',
        keywords: List<String>.from(j['keywords'] ?? const []),
        frases: List<String>.from(j['frases'] ?? const []),
        respuesta: j['respuesta'] as String? ?? '',
        roles: List<String>.from(j['roles'] ?? const ['*']),
        estado: (j['estado'] ?? 'disponible') as String,
        chips: List<String>.from(j['chips'] ?? const []),
        accion: j['accion'] as String?,
        prioridad: (j['prioridad'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoria': categoria,
        'keywords': keywords,
        'frases': frases,
        'respuesta': respuesta,
        'roles': roles,
        'estado': estado,
        'chips': chips,
        'accion': accion,
        'prioridad': prioridad,
      };

  bool appliesToRole(String role) {
    if (roles.contains('*')) return true;
    final normalized = role.toLowerCase().trim();
    // Support admin/superadmin equivalence
    if (normalized == 'admin' && (roles.contains('admin') || roles.contains('superadmin'))) {
      return true;
    }
    if (normalized == 'superadmin' && (roles.contains('admin') || roles.contains('superadmin'))) {
      return true;
    }
    return roles.map((r) => r.toLowerCase().trim()).contains(normalized);
  }
}
