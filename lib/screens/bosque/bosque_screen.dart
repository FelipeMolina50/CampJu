import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../models/bosque_model.dart';
import '../../../models/miembro_model.dart';
import '../../../models/solicitud_model.dart';
import '../../../services/auth_provider.dart';
import '../../../services/bosque_service.dart';
import '../../../services/admin_service.dart';

class BosqueScreen extends StatefulWidget {
  const BosqueScreen({super.key});

  @override
  State<BosqueScreen> createState() => _BosqueScreenState();
}

class _BosqueScreenState extends State<BosqueScreen> {
  final BosqueService _bosqueService = BosqueService();
  List<BosqueModel> _misBosques = [];
  bool _isLoading = false;
  bool _isCreating = false;

  MiembroModel? _miMembresia;
  SolicitudModel? _miSolicitud;
  List<MiembroModel> _miembrosDelBosque = [];
  List<SolicitudModel> _solicitudesPendientes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool get _isSuperAdmin {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    return AppConstants.isSuperAdmin(firebaseUser);
  }

  bool get _isAdmin {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    return _isSuperAdmin || (user != null && user.role.index == 2);
  }

  bool get _isCoordinador {
    return _miMembresia?.rol == 'coordinador';
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user != null) {
        // FORZAR SINCRONIZACIÓN DE PERFIL: 
        // Esto asegura que si el Coordinador te aceptó, tu perfil local se entere de inmediato.
        await authProvider.reloadUser();
        
        _miMembresia = await _bosqueService.obtenerMiMembresia(user.id);
        
        if (_miMembresia != null) {
          try {
            final bosqueReal = await _bosqueService.obtenerBosque(_miMembresia!.bosqueId);
            
            if (bosqueReal == null) {
              _bosqueService.cancelarMembresia(_miMembresia!.id).catchError((e) => debugPrint('Error al borrar miembro: $e'));
              final adminService = AdminService();
              await adminService.actualizarUsuario(user.id, {'bosqueId': null, 'fechaIngresoBosque': null});
              setState(() { _miMembresia = null; _miembrosDelBosque = []; });
            } else {
              _miembrosDelBosque = await _bosqueService.obtenerMiembros(_miMembresia!.bosqueId);
              if (_isCoordinador) {
                _solicitudesPendientes = await _bosqueService.obtenerSolicitudes(_miMembresia!.bosqueId);
              }
            }
          } catch (e) {
            debugPrint('Error verificando bosque: $e');
          }
        }
        
        if (_miMembresia == null) {
          _miSolicitud = await _bosqueService.obtenerMiSolicitud(user.id);
        }
        
        _misBosques = await _bosqueService.obtenerBosques();
      }
    } catch (e) {
      debugPrint('Error loading bosque data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enviarSolicitud(BosqueModel bosque) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    if (!user.perfilCompleto) {
      _mostrarDialogoPerfilIncompleto();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final solicitud = SolicitudModel(
        id: const Uuid().v4(),
        userId: user.id,
        userName: user.name,
        bosqueId: bosque.id,
        bosqueNombre: bosque.nombre,
        createdAt: DateTime.now(),
      );
      await _bosqueService.crearSolicitud(solicitud);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar solicitud: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _abandonarBosque() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null || _miMembresia == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Abandonar grupo?'),
        content: const Text('Dejarás de pertenecer a este bosque y ya no podrás participar en sus actividades.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, salir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _bosqueService.abandonarBosque(user.id, _miMembresia!.bosqueId);
        await authProvider.reloadUser();
        await _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al salir: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarDialogoPerfilIncompleto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 8), Text('Perfil Incompleto')]),
        content: const Text('Para unirte a un bosque, primero debes completar tus datos personales en la sección de Perfil.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.editarPerfil);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Ir al Perfil'),
          ),
        ],
      ),
    );
  }

  Future<void> _aceptarSolicitud(SolicitudModel solicitud) async {
    setState(() => _isLoading = true);
    try {
      await _bosqueService.aceptarSolicitud(solicitud);
      await _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al aceptar: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rechazarSolicitud(SolicitudModel solicitud) async {
    setState(() => _isLoading = true);
    try {
      await _bosqueService.rechazarSolicitud(solicitud.id);
      await _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al rechazar: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelarSolicitud() async {
    if (_miSolicitud == null) return;
    setState(() => _isLoading = true);
    try {
      await _bosqueService.cancelarSolicitud(_miSolicitud!.id);
      await _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cancelar: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  void _mostrarCrearBosque() {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final zonaController = TextEditingController();
    final buscarController = TextEditingController();
    String? coordinadorSeleccionadoId;
    String? coordinadorSeleccionadoNombre;
    final adminService = AdminService();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setDialogState) => AlertDialog(
          title: const Text('Nuevo Bosque'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(label: 'Nombre del Bosque', controller: nombreController),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'Descripción', controller: descripcionController, maxLines: 2),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'Zona', controller: zonaController),
                  const SizedBox(height: 24),
                  const Text('Asignar Coordinador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: buscarController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o documento...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: adminService.obtenerCandidatosACoordinador(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final query = buscarController.text.toLowerCase();
                      final candidatos = (snapshot.data ?? []).where((c) {
                        final name = (c['name'] ?? '').toString().toLowerCase();
                        final doc = (c['numeroDocumento'] ?? '').toString().toLowerCase();
                        return name.contains(query) || doc.contains(query);
                      }).toList();
                      return Container(
                        height: 150,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                        child: ListView.builder(
                          itemCount: candidatos.length,
                          itemBuilder: (ctx, idx) {
                            final c = candidatos[idx];
                            return ListTile(
                              title: Text(c['name'], style: const TextStyle(fontSize: 14)),
                              subtitle: Text('Doc: ${c['numeroDocumento']}', style: const TextStyle(fontSize: 12)),
                              selected: coordinadorSeleccionadoId == c['uid'],
                              selectedTileColor: AppColors.primary.withOpacity(0.1),
                              onTap: () => setDialogState(() { coordinadorSeleccionadoId = c['uid']; coordinadorSeleccionadoNombre = c['name']; }),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            CustomButton(
              label: 'Crear Bosque',
              onPressed: coordinadorSeleccionadoId != null ? () async {
                Navigator.pop(dialogContext);
                setState(() => _isCreating = true);
                try {
                  final bosque = BosqueModel(
                    id: const Uuid().v4(),
                    nombre: nombreController.text.trim(),
                    descripcion: descripcionController.text.trim(),
                    zona: zonaController.text.trim(),
                    liderId: coordinadorSeleccionadoId!,
                    miembros: 1,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await _bosqueService.crearBosque(bosque, Provider.of<AuthProvider>(context, listen: false).user!.id, coordinadorSeleccionadoId!, coordinadorSeleccionadoNombre!);
                  _loadData();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setState(() => _isCreating = false);
                }
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isCreating) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_isSuperAdmin) return _buildExploreView();
    if (_miMembresia != null) return _buildJoinedView();
    if (_miSolicitud != null) return _buildPendingView();
    return _buildExploreView();
  }

  Widget _buildExploreView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isSuperAdmin ? 'Gestión de Bosques' : 'Explorar Bosques', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(_isSuperAdmin ? 'Panel de control de Super Admin' : 'Encuentra tu comunidad CampJu', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => _handleLogout(context)),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: _misBosques.map((bosque) => _buildBosqueCard(bosque)).toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin ? FloatingActionButton(backgroundColor: AppColors.primary, onPressed: _mostrarCrearBosque, child: const Icon(Icons.add, color: Colors.white)) : null,
    );
  }

  Widget _buildBosqueCard(BosqueModel bosque) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.forest, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: Text(bosque.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 12),
            Text(bosque.descripcion, style: const TextStyle(color: Colors.grey, fontSize: 14), maxLines: 2),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [const Icon(Icons.people, size: 16, color: Colors.grey), const SizedBox(width: 4), Text('${bosque.miembrosCount} miembros', style: const TextStyle(fontSize: 12, color: Colors.grey))]),
                ElevatedButton(
                  onPressed: () => _enviarSolicitud(bosque),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Unirse'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: const BoxDecoration(color: AppColors.accentYellow, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
            child: Row(
              children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Solicitud Pendiente', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)), Text('Tu solicitud está en revisión', style: TextStyle(color: Colors.white, fontSize: 14))])),
                IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => _handleLogout(context)),
              ],
            ),
          ),
          const Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.hourglass_empty, size: 64, color: AppColors.accentYellow), SizedBox(height: 24), Text('Esperando aprobación del líder...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Padding(padding: EdgeInsets.all(24), child: Text('Te avisaremos cuando seas aceptado en el bosque.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))]))),
          Padding(padding: const EdgeInsets.all(24), child: CustomButton(label: 'Cancelar Solicitud', onPressed: _cancelarSolicitud)),
        ],
      ),
    );
  }

  Widget _buildJoinedView() {
    return DefaultTabController(
      length: _isCoordinador ? 3 : 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_isSuperAdmin) IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => setState(() => _miMembresia = null)),
                      Expanded(child: Text(_miMembresia?.nombre ?? 'Mi Bosque', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
                      IconButton(icon: const Icon(Icons.exit_to_app, color: Colors.white), onPressed: _abandonarBosque, tooltip: 'Salir del bosque'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(children: [Icon(Icons.location_on, color: Colors.white70, size: 14), SizedBox(width: 4), Text('Campamento Base', style: TextStyle(color: Colors.white70, fontSize: 13))]),
                ],
              ),
            ),
            TabBar(labelColor: AppColors.primary, indicatorColor: AppColors.primary, tabs: [const Tab(text: 'Miembros'), const Tab(text: 'Chat'), if (_isCoordinador) const Tab(text: 'Solicitudes')]),
            Expanded(child: TabBarView(children: [_buildForestProfile(), _buildForestChat(), if (_isCoordinador) _buildRequestsTab()])),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_solicitudesPendientes.isEmpty) return const Center(child: Text('No hay solicitudes pendientes', style: TextStyle(color: Colors.grey)));
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _solicitudesPendientes.length,
        itemBuilder: (context, index) {
          final s = _solicitudesPendientes[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Row(
              children: [
                Expanded(child: Text(s.userName, style: const TextStyle(fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _rechazarSolicitud(s)),
                IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _aceptarSolicitud(s)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildForestProfile() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Miembros del Equipo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ..._miembrosDelBosque.map((m) => ListTile(
          leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: Icon(m.rol == 'coordinador' ? Icons.badge : Icons.person, color: AppColors.primary, size: 20)),
          title: Text(m.nombre),
          subtitle: Text(m.rol),
        )),
      ],
    );
  }

  Widget _buildForestChat() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.forum_outlined, size: 48, color: Colors.grey), SizedBox(height: 16), Text('El chat se habilitará próximamente', style: TextStyle(color: Colors.grey))]));
  }
}