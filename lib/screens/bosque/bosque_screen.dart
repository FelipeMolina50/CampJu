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
  BosqueModel? _miBosqueActual;
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
    return _miMembresia?.rol == 'coordinador' || (_isAdmin && _miBosqueActual != null && _miMembresia == null);
  }

  Future<void> _verBosqueComoAdmin(BosqueModel bosque) async {
    setState(() => _isLoading = true);
    try {
      _miembrosDelBosque = await _bosqueService.obtenerMiembros(bosque.id);
      _solicitudesPendientes = await _bosqueService.obtenerSolicitudes(bosque.id);
      setState(() {
        _miBosqueActual = bosque;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user != null) {
        await authProvider.reloadUser();
        _miMembresia = await _bosqueService.obtenerMiMembresia(user.id);
        
        if (_miMembresia != null) {
          try {
            _miBosqueActual = await _bosqueService.obtenerBosque(_miMembresia!.bosqueId);
            
            if (_miBosqueActual == null) {
              _bosqueService.cancelarMembresia(_miMembresia!.id).catchError((e) => debugPrint('Error al borrar miembro: $e'));
              final adminService = AdminService();
              await adminService.actualizarUsuario(user.id, {'bosqueId': null, 'fechaIngresoBosque': null});
              setState(() { _miMembresia = null; _miBosqueActual = null; _miembrosDelBosque = []; });
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

  void _mostrarCrearBosque() {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final zonaController = TextEditingController();
    final buscarController = TextEditingController();
    String? coordinadorSeleccionadoId;
    String? coordinadorSeleccionadoNombre;
    bool confirmarAsignacion = false;
    String? errorMessage;
    final adminService = AdminService();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setDialogState) => AlertDialog(
          title: const Text('Crear Nuevo Bosque'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  CustomTextField(label: 'Nombre del Bosque', controller: nombreController),
                  const SizedBox(height: 12),
                  CustomTextField(label: 'Descripción / Propósito', controller: descripcionController, maxLines: 2),
                  const SizedBox(height: 12),
                  CustomTextField(label: 'Zona Geográfica', controller: zonaController),
                  const SizedBox(height: 20),
                  const Divider(),
                  const Text('Asignar Coordinador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: buscarController,
                    decoration: InputDecoration(
                      hintText: 'Nombre o Documento...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: adminService.obtenerCandidatosACoordinador(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                      
                      final query = buscarController.text.toLowerCase();
                      final candidatos = snapshot.data!.where((c) {
                        // 1. Excluir al Super Admin
                        if (c['email'] == AppConstants.superAdminEmail) return false;
                        
                        // 2. Búsqueda por nombre o documento
                        final name = (c['name'] ?? '').toString().toLowerCase();
                        final apellidos = (c['apellidos'] ?? '').toString().toLowerCase();
                        final doc = (c['numeroDocumento'] ?? '').toString().toLowerCase();
                        final fullName = '$name $apellidos';
                        
                        return fullName.contains(query) || doc.contains(query);
                      }).toList();

                      if (candidatos.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No se encontraron candidatos', style: TextStyle(color: Colors.grey)));

                      return Container(
                        height: 180,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                        child: ListView.separated(
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemCount: candidatos.length,
                          itemBuilder: (ctx, idx) {
                            final c = candidatos[idx];
                            final name = c['name'] ?? '';
                            final apellidos = c['apellidos'] ?? '';
                            final doc = c['numeroDocumento'] ?? 'Sin doc';
                            final isSelected = coordinadorSeleccionadoId == c['uid'];

                            return ListTile(
                              visualDensity: VisualDensity.compact,
                              title: Text('$name $apellidos', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('ID: $doc', style: const TextStyle(fontSize: 12)),
                              selected: isSelected,
                              selectedTileColor: AppColors.primary.withOpacity(0.1),
                              onTap: () => setDialogState(() {
                                coordinadorSeleccionadoId = c['uid'];
                                coordinadorSeleccionadoNombre = '$name $apellidos';
                              }),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  if (coordinadorSeleccionadoId != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: confirmarAsignacion,
                          onChanged: (val) => setDialogState(() => confirmarAsignacion = val ?? false),
                        ),
                        Expanded(
                          child: Text(
                            'Confirmo que deseo asignar a $coordinadorSeleccionadoNombre como coordinador de este bosque.',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: (coordinadorSeleccionadoId == null || !confirmarAsignacion) ? null : () async {
                if (nombreController.text.trim().isEmpty ||
                    descripcionController.text.trim().isEmpty ||
                    zonaController.text.trim().isEmpty) {
                  setDialogState(() {
                    errorMessage = 'Por favor complete todos los campos obligatorios.';
                  });
                  return;
                }
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
                  await _bosqueService.crearBosque(
                    bosque, 
                    Provider.of<AuthProvider>(context, listen: false).user!.id, 
                    coordinadorSeleccionadoId!, 
                    coordinadorSeleccionadoNombre!
                  );
                  _loadData();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setState(() => _isCreating = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Crear Bosque'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarConfirmacionEliminar(String bosqueId) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final adminService = AdminService();
    String? errorText;
    bool isAuthenticating = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Eliminar Bosque', style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Para confirmar la eliminación, ingrese las credenciales de Super Admin:'),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Correo electrónico',
                  errorText: errorText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (_) => setDialogState(() => errorText = null),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (_) => setDialogState(() => errorText = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isAuthenticating ? null : () => Navigator.pop(dialogContext), 
              child: const Text('Cancelar')
            ),
            ElevatedButton(
              onPressed: isAuthenticating ? null : () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                if (email.isEmpty || password.isEmpty) {
                  setDialogState(() => errorText = 'Complete ambos campos');
                  return;
                }
                if (email != AppConstants.superAdminEmail) {
                  setDialogState(() => errorText = 'Correo no válido');
                  return;
                }
                
                if (password != 'pipelin50') {
                  setDialogState(() => errorText = 'Contraseña incorrecta');
                  return;
                }
                
                setDialogState(() => isAuthenticating = true);
                
                try {
                  if (!mounted) return;
                  Navigator.pop(dialogContext); // Close dialog
                  
                  setState(() => _isLoading = true); // Main screen loading
                  
                  await adminService.eliminarBosque(bosqueId, email);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bosque eliminado con éxito'), backgroundColor: Colors.green),
                    );
                    await _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al eliminar: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
                    );
                    setState(() => _isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: isAuthenticating 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviarSolicitud(BosqueModel bosque) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;
    if (!user.perfilCompleto) { _mostrarDialogoPerfilIncompleto(); return; }
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: const Text('¿Abandonar este Bosque?'),
        content: const Text('Perderás el acceso al chat y a las actividades.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Confirmar Salida')),
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        content: const Text('Para unirte a un bosque, primero debes completar tus datos personales.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.editarPerfil); }, child: const Text('Ir al Perfil')),
        ],
      ),
    );
  }

  Future<void> _aceptarSolicitud(SolicitudModel solicitud) async {
    setState(() => _isLoading = true);
    try { await _bosqueService.aceptarSolicitud(solicitud); await _loadData(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _rechazarSolicitud(SolicitudModel solicitud) async {
    setState(() => _isLoading = true);
    try { await _bosqueService.rechazarSolicitud(solicitud.id); await _loadData(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _cancelarSolicitud() async {
    if (_miSolicitud == null) return;
    setState(() => _isLoading = true);
    try { await _bosqueService.cancelarSolicitud(_miSolicitud!.id); await _loadData(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isCreating) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_miBosqueActual != null) return _buildJoinedView();
    if (_isSuperAdmin) return _buildExploreView();
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
      floatingActionButton: _isAdmin ? FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _mostrarCrearBosque,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
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
                if (_isSuperAdmin)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _mostrarConfirmacionEliminar(bosque.id),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(bosque.descripcion, style: const TextStyle(color: Colors.grey, fontSize: 14), maxLines: 2),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [const Icon(Icons.people, size: 16, color: Colors.grey), const SizedBox(width: 4), Text('${bosque.miembrosCount} miembros', style: const TextStyle(fontSize: 12, color: Colors.grey))]),
                Row(
                  children: [
                    if (_isAdmin)
                      OutlinedButton(
                        onPressed: () => _verBosqueComoAdmin(bosque),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text('Ver'),
                      ),
                    if (_isAdmin && !_isSuperAdmin) const SizedBox(width: 8),
                    if (!_isSuperAdmin)
                      ElevatedButton(
                        onPressed: () => _enviarSolicitud(bosque),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text('Unirse'),
                      ),
                  ],
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
          const Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.hourglass_empty, size: 64, color: AppColors.accentYellow), SizedBox(height: 24), Text('Esperando aprobación...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Padding(padding: EdgeInsets.all(24), child: Text('El líder del bosque revisará tu solicitud pronto.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))]))),
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
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(_miBosqueActual?.nombre ?? 'Mi Bosque', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
                      if (_isAdmin && _miMembresia == null) IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => setState(() => _miBosqueActual = null)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Territorio de Aventura y Comunidad', style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 0.5)),
                ],
              ),
            ),
            TabBar(labelColor: AppColors.primary, unselectedLabelColor: Colors.grey, indicatorColor: AppColors.primary, indicatorWeight: 3, tabs: [const Tab(text: 'Miembros'), const Tab(text: 'Chat'), if (_isCoordinador) const Tab(text: 'Solicitudes')]),
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
                CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: const Icon(Icons.person, color: AppColors.primary)),
                const SizedBox(width: 12),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Miembros del Equipo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        ..._miembrosDelBosque.map((m) {
          final bool isMe = m.usuarioId == currentUser?.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isMe ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isMe ? AppColors.primary : AppColors.primary.withOpacity(0.1), 
                child: Icon(m.rol == 'coordinador' ? Icons.badge : Icons.person, color: isMe ? Colors.white : AppColors.primary, size: 20)
              ),
              title: Text(isMe ? '${m.nombre} (Tú)' : m.nombre, style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal, color: isMe ? AppColors.primary : AppColors.textPrimary)),
              subtitle: Text(m.rol, style: TextStyle(color: isMe ? AppColors.primary.withOpacity(0.7) : Colors.grey)),
              trailing: isMe ? const Icon(Icons.star, color: AppColors.primary, size: 16) : null,
            ),
          );
        }).toList(),
        if (_miMembresia != null) ...[
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _abandonarBosque,
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            label: const Text('Abandonar este Bosque'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('Si sales, deberás solicitar unirte de nuevo.', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ],
    );
  }

  Widget _buildForestChat() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.forum_outlined, size: 48, color: Colors.grey), SizedBox(height: 16), Text('El chat se habilitará próximamente', style: TextStyle(color: Colors.grey))]));
  }
}