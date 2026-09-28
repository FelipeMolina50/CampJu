import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/bosque_model.dart';
import '../../../models/user_model.dart';
import '../../../models/evento_model.dart';
import '../../../models/inscripcion_model.dart';
import '../../../services/auth_provider.dart';
import '../../../services/bosque_service.dart';
import '../../../services/evento_service.dart';
import '../../../services/reporte_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BosqueService _bosqueService = BosqueService();
  final EventoService _eventoService = EventoService();
  String _searchUserQuery = '';
  EventoModel? _selectedEvento;
  String _filtroEstadoInscripcion = 'aprobada';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).user;

    // Validación estricta de seguridad en UI: solo Super Admin
    if (currentUser == null || currentUser.role.index != 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Restringido')),
        body: const Center(
          child: Text(
            'No tienes permisos de Super Administrador para ver este panel.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panel de Administracion'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Resumen'),
            Tab(icon: Icon(Icons.people_outline), text: 'Usuarios'),
            Tab(icon: Icon(Icons.forest_outlined), text: 'Bosques'),
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Inscripciones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResumenTab(),
          _buildUsuariosTab(),
          _buildBosquesTab(currentUser),
          _buildInscripcionesTab(currentUser),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: RESUMEN Y MÉTRICAS
  // -------------------------------------------------------------
  Widget _buildResumenTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bosques').snapshots(),
          builder: (context, bosqueSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('solicitudes').where('estado', isEqualTo: 'pendiente').snapshots(),
              builder: (context, solSnap) {
                if (userSnap.connectionState == ConnectionState.waiting ||
                    bosqueSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = userSnap.data?.docs ?? [];
                final bosques = bosqueSnap.data?.docs ?? [];
                final solicitudes = solSnap.data?.docs ?? [];

                final campistasCount = users.where((u) => ((u.data() as Map<String, dynamic>)['role'] ?? 0) == 0).length;
                final coordinadoresCount = users.where((u) => ((u.data() as Map<String, dynamic>)['role'] ?? 0) == 1).length;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Metricas Globales',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('Campistas', '$campistasCount', Icons.group_outlined, AppColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMetricCard('Coordinadores', '$coordinadoresCount', Icons.badge_outlined, AppColors.secondary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('Bosques', '${bosques.length}', Icons.forest_outlined, AppColors.accent)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMetricCard('Solicitudes', '${solicitudes.length}', Icons.pending_actions_outlined, AppColors.error)),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: GESTIÓN DE USUARIOS Y ROLES
  // -------------------------------------------------------------
  Widget _buildUsuariosTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o correo...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            ),
            onChanged: (val) => setState(() => _searchUserQuery = val.toLowerCase().trim()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              final filtered = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = '${data['name'] ?? ''} ${data['apellidos'] ?? ''}'.toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                return name.contains(_searchUserQuery) || email.contains(_searchUserQuery);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No se encontraron usuarios', style: TextStyle(color: AppColors.textSecondary)));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final data = filtered[index].data() as Map<String, dynamic>;
                  final userId = filtered[index].id;
                  final roleIndex = data['role'] as int? ?? 0;
                  final nombre = '${data['name'] ?? ''} ${data['apellidos'] ?? ''}'.trim();
                  final email = data['email'] ?? 'Sin correo';
                  final roleName = roleIndex == 2 ? 'Super Admin' : (roleIndex == 1 ? 'Coordinador' : 'Campista');

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      title: Text(nombre.isNotEmpty ? nombre : email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('$email - Rol: $roleName', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      trailing: IconButton(
                        icon: const Icon(Icons.manage_accounts_outlined, color: AppColors.primary),
                        tooltip: 'Editar rol o bosque',
                        onPressed: () => _mostrarDialogoEditarUsuario(userId, data),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoEditarUsuario(String targetUserId, Map<String, dynamic> targetData) async {
    int selectedRole = targetData['role'] as int? ?? 0;
    String? selectedBosqueId = targetData['bosqueId'] as String?;

    final bosques = await _bosqueService.obtenerBosques();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Administrar Usuario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${targetData['name'] ?? ''} ${targetData['apellidos'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(targetData['email'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    const Text('Asignar Rol:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    DropdownButtonFormField<int>(
                      value: selectedRole,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Campista')),
                        DropdownMenuItem(value: 1, child: Text('Coordinador')),
                        DropdownMenuItem(value: 2, child: Text('Super Admin')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Bosque asignado:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    DropdownButtonFormField<String?>(
                      value: selectedBosqueId,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Ninguno')),
                        ...bosques.map((b) => DropdownMenuItem(value: b.id, child: Text(b.nombre))),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedBosqueId = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    // Regla de negocio: si es coordinador debe tener bosque asignado
                    if (selectedRole == 1 && (selectedBosqueId == null || selectedBosqueId!.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Un coordinador debe tener un bosque asignado obligatoriamente.')),
                      );
                      return;
                    }

                    Navigator.pop(dialogCtx);

                    final batch = FirebaseFirestore.instance.batch();
                    final userRef = FirebaseFirestore.instance.collection('users').doc(targetUserId);

                    batch.update(userRef, {
                      'role': selectedRole,
                      'bosqueId': selectedBosqueId,
                    });

                    // Si se le asigna como coordinador de un bosque, actualizar liderId del bosque
                    if (selectedRole == 1 && selectedBosqueId != null) {
                      final bosqueRef = FirebaseFirestore.instance.collection('bosques').doc(selectedBosqueId);
                      batch.update(bosqueRef, {'liderId': targetUserId});
                    }

                    await batch.commit();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Usuario actualizado correctamente')),
                      );
                    }
                  },
                  child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 3: CRUD DE BOSQUES
  // -------------------------------------------------------------
  Widget _buildBosquesTab(UserModel currentUser) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Crear Nuevo Bosque', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => _mostrarCrearBosqueDialog(currentUser),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bosques').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No hay bosques registrados.', style: TextStyle(color: AppColors.textSecondary)));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final bosqueId = docs[index].id;
                  final nombre = data['nombre'] ?? 'Bosque';
                  final zona = data['zona'] ?? 'Sin zona';
                  final miembrosCount = data['miembros'] ?? 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryContainer,
                        child: Icon(Icons.forest, color: AppColors.primary),
                      ),
                      title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('$zona - $miembrosCount miembros', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        tooltip: 'Eliminar bosque',
                        onPressed: () async {
                          final confirmar = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar Bosque'),
                              content: Text('¿Estas seguro de eliminar el bosque "$nombre"? Esta accion retirara a sus miembros.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirmar == true) {
                            try {
                              await _bosqueService.eliminarBosque(bosqueId, currentUser.email);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Bosque eliminado correctamente')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _mostrarCrearBosqueDialog(UserModel currentUser) {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final zonaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Bosque'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Bosque *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: zonaCtrl,
                decoration: const InputDecoration(labelText: 'Municipio / Zona *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripcion', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty || zonaCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nombre y zona son requeridos')),
                );
                return;
              }

              Navigator.pop(ctx);

              final nuevoBosque = BosqueModel(
                id: FirebaseFirestore.instance.collection('bosques').doc().id,
                nombre: nombreCtrl.text.trim(),
                descripcion: descCtrl.text.trim(),
                zona: zonaCtrl.text.trim(),
                liderId: currentUser.id,
                fotoUrl: '',
                miembros: 1,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              try {
                await _bosqueService.crearBosque(
                  nuevoBosque,
                  currentUser.id,
                  currentUser.id,
                  '${currentUser.name} ${currentUser.apellidos}'.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bosque creado exitosamente')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al crear bosque: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Crear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 4: INSCRIPCIONES Y REPORTES (FASE 5D)
  // -------------------------------------------------------------
  Widget _buildInscripcionesTab(UserModel currentUser) {
    if (_selectedEvento == null) {
      return _buildListaEventosParaReporte();
    }
    return _buildDetalleInscritosEvento(currentUser, _selectedEvento!);
  }

  Widget _buildListaEventosParaReporte() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('eventos').orderBy('fechaInicio', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('No hay eventos registrados en la plataforma', style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        final eventos = docs.map((d) => EventoModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Selecciona un Evento para ver Inscritos y Reportes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ...eventos.map((ev) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Icon(_getIconForEvento(ev.tipo), color: AppColors.primary),
                  ),
                  title: Text(ev.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lugar: ${ev.lugar} - ${ev.municipioSede}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                              child: Text(ev.tipo.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent)),
                            ),
                            const SizedBox(width: 8),
                            Text('Aprobados: ${ev.aprobadosCount}${ev.cupoTotal != null ? ' / ${ev.cupoTotal}' : ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
                  onTap: () {
                    setState(() {
                      _selectedEvento = ev;
                      _filtroEstadoInscripcion = 'aprobada';
                    });
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildDetalleInscritosEvento(UserModel currentUser, EventoModel evento) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bosques').snapshots(),
      builder: (context, bosqueSnap) {
        final bosquesDocs = bosqueSnap.data?.docs ?? [];
        final Map<String, String> bosquesNombres = {};
        final Map<String, String> coordinadoresNombres = {};

        for (final b in bosquesDocs) {
          final data = b.data() as Map<String, dynamic>;
          bosquesNombres[b.id] = data['nombre'] ?? b.id;
          coordinadoresNombres[b.id] = data['liderNombre'] ?? 'No asignado';
        }

        return StreamBuilder<List<InscripcionModel>>(
          stream: _eventoService.streamInscripcionesEvento(evento.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final todasInscripciones = snapshot.data ?? [];
            final totalAprobados = todasInscripciones.where((i) => i.estado == 'aprobada').length;
            final totalPendientes = todasInscripciones.where((i) => i.estado == 'pendiente').length;
            final totalObservadas = todasInscripciones.where((i) => i.estado == 'observada').length;
            final totalRechazadas = todasInscripciones.where((i) => i.estado == 'rechazada').length;

            final filtradas = _filtroEstadoInscripcion == 'todas'
                ? todasInscripciones
                : todasInscripciones.where((i) => i.estado == _filtroEstadoInscripcion).toList();

            // Agrupación por municipio y bosque
            final Map<String, Map<String, List<InscripcionModel>>> agrupado = {};
            for (final ins in filtradas) {
              final mun = ins.municipio.trim().isEmpty ? 'Sin Municipio' : ins.municipio.trim();
              final bId = ins.bosqueId.trim().isEmpty ? 'Sin Bosque' : ins.bosqueId.trim();
              agrupado.putIfAbsent(mun, () => {});
              agrupado[mun]!.putIfAbsent(bId, () => []);
              agrupado[mun]![bId]!.add(ins);
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Barra de retorno al selector
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _selectedEvento = null),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(evento.titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('${evento.lugar} - ${evento.municipioSede}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Botón de exportación a CSV/Excel
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                  label: const Text('Exportar Reporte (Excel / CSV)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: todasInscripciones.isEmpty
                      ? null
                      : () async {
                          try {
                            await ReporteService.exportarInscripcionesCsv(
                              evento: evento,
                              inscripciones: filtradas.isEmpty ? todasInscripciones : filtradas,
                              nombresBosques: bosquesNombres,
                              nombresCoordinadores: coordinadoresNombres,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al exportar: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        },
                ),
                const SizedBox(height: 16),

                // Contadores métricos de estado
                Row(
                  children: [
                    Expanded(child: _buildMetricCard('Aprobados', '$totalAprobados', Icons.check_circle_outline, Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard('Pendientes', '$totalPendientes', Icons.hourglass_top, Colors.amber[800]!)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard('Observadas', '$totalObservadas', Icons.visibility_outlined, Colors.orange)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard('Rechazadas', '$totalRechazadas', Icons.cancel_outlined, Colors.red)),
                  ],
                ),
                const SizedBox(height: 16),

                // Filtro por estado
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('aprobada', 'Aprobadas ($totalAprobados)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('pendiente', 'Pendientes ($totalPendientes)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('observada', 'Observadas ($totalObservadas)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('rechazada', 'Rechazadas ($totalRechazadas)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('todas', 'Todas (${todasInscripciones.length})'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Lista agrupada por municipio y bosque
                if (agrupado.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Text(
                      'No hay inscripciones con estado "$_filtroEstadoInscripcion"',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...agrupado.entries.map((munEntry) {
                    final municipio = munEntry.key;
                    final bosquesMap = munEntry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: Text(
                          'Municipio: $municipio',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                        ),
                        subtitle: Text(
                          '${bosquesMap.values.fold<int>(0, (sum, list) => sum + list.length)} inscrito(s)',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        children: bosquesMap.entries.map((bEntry) {
                          final bosqueId = bEntry.key;
                          final inscritos = bEntry.value;
                          final bNombre = bosquesNombres[bosqueId] ?? bosqueId;

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.forest, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text('Bosque: $bNombre', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const Spacer(),
                                    Text('${inscritos.length} campista(s)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                                const Divider(height: 16),
                                ...inscritos.map((ins) => _buildInscritoItem(ins, currentUser, evento)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String valor, String etiqueta) {
    final isSelected = _filtroEstadoInscripcion == valor;
    return ChoiceChip(
      label: Text(etiqueta, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filtroEstadoInscripcion = valor);
        }
      },
    );
  }

  Widget _buildInscritoItem(InscripcionModel ins, UserModel currentUser, EventoModel evento) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(ins.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getColorForEstado(ins.estado).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ins.estado.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getColorForEstado(ins.estado)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Doc: ${ins.documentoId} | Tel: ${ins.telefono} | Sexo: ${ins.sexo} | Nivel: ${ins.nivel}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (ins.estado == 'pendiente' || ins.estado == 'observada') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      final motivoCtrl = TextEditingController();
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Rechazar Inscripcion'),
                          content: TextField(
                            controller: motivoCtrl,
                            decoration: const InputDecoration(labelText: 'Motivo del rechazo *'),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );

                      if (confirmar == true) {
                        await _eventoService.rechazarInscripcion(
                          inscripcionId: ins.id,
                          motivo: motivoCtrl.text.trim(),
                          revisorId: currentUser.id,
                        );
                      }
                    },
                    child: const Text('Rechazar', style: TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () async {
                      try {
                        await _eventoService.aprobarInscripcion(
                          inscripcionId: ins.id,
                          eventoId: evento.id,
                          revisorId: currentUser.id,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Inscripcion aprobada exitosamente')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
                    child: const Text('Aprobar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForEvento(String tipo) {
    switch (tipo) {
      case 'actividad':
        return Icons.local_activity_outlined;
      case 'campista_dia':
        return Icons.wb_sunny_outlined;
      case 'municipal':
        return Icons.location_city_outlined;
      case 'interzonal':
        return Icons.share_location_outlined;
      case 'departamental':
        return Icons.map_outlined;
      case 'nacional':
        return Icons.flag_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  Color _getColorForEstado(String estado) {
    switch (estado) {
      case 'aprobada':
        return Colors.green;
      case 'pendiente':
        return Colors.amber[800]!;
      case 'observada':
        return Colors.orange;
      case 'rechazada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

