import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../models/bosque_model.dart';
import '../../../models/miembro_model.dart';
import '../../../models/solicitud_model.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_provider.dart';
import '../../../services/bosque_service.dart';
import '../../../services/admin_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/supabase_storage_service.dart';
import '../../../models/mensaje_model.dart';
import '../../../models/inscripcion_model.dart';
import '../../../models/evento_model.dart';
import '../../../services/evento_service.dart';
import '../../../services/reporte_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/camping_chat_background.dart';

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
  Map<String, UserModel> _datosCampistas = {};
  
  int _chatLimit = 30;
  final ScrollController _chatScrollController = ScrollController();

  Future<void> _cargarUsuariosMiembros() async {
    final Map<String, UserModel> mapa = {};
    for (final m in _miembrosDelBosque) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(m.usuarioId).get();
        if (doc.exists && doc.data() != null) {
          mapa[m.usuarioId] = UserModel.fromJson({...doc.data()!, 'id': doc.id});
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _datosCampistas = mapa;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _chatScrollController.addListener(() {
      if (_chatScrollController.position.pixels >= _chatScrollController.position.maxScrollExtent - 50) {
        setState(() {
          _chatLimit += 30;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _chatScrollController.dispose();
    super.dispose();
  }

  void _mostrarBienvenidaCoordinador(String bosqueNombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Felicidades!', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, color: AppColors.accentYellow, size: 64),
            const SizedBox(height: 16),
            Text('Has sido asignado como Coordinador del bosque:', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(bosqueNombre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            const SizedBox(height: 16),
            const Text('Ahora tienes la responsabilidad de guiar a tu equipo. ¡Mucho éxito!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('¡Entendido!'),
          ),
        ],
      ),
    );
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
      _cargarUsuariosMiembros();
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
            // Actualizar ultima lectura
            _bosqueService.actualizarUltimaLectura(_miMembresia!.id);
            
            _miBosqueActual = await _bosqueService.obtenerBosque(_miMembresia!.bosqueId);
            
            if (_miBosqueActual == null) {
              _bosqueService.cancelarMembresia(_miMembresia!.id).catchError((e) => debugPrint('Error al borrar miembro: $e'));
              final adminService = AdminService();
              await adminService.actualizarUsuario(user.id, {'bosqueId': null, 'fechaIngresoBosque': null});
              setState(() { _miMembresia = null; _miBosqueActual = null; _miembrosDelBosque = []; });
            } else {
              _miembrosDelBosque = await _bosqueService.obtenerMiembros(_miMembresia!.bosqueId);
              _cargarUsuariosMiembros();
              if (_isCoordinador) {
                _solicitudesPendientes = await _bosqueService.obtenerSolicitudes(_miMembresia!.bosqueId);
                
                final firestoreService = FirestoreService();
                final doc = await firestoreService.getDocument('users', user.id);
                if (doc.exists && (doc.data() as Map<String, dynamic>)['vistoBienvenidaCoordinador'] != true) {
                  await firestoreService.updateDocument('users', user.id, {'vistoBienvenidaCoordinador': true});
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _mostrarBienvenidaCoordinador(_miBosqueActual!.nombre);
                    });
                  }
                }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D3323), // Verde bosque profundo campamento
                Color(0xFF1B4D3E),
                Color(0xFF236349),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  if (_isAdmin && _miMembresia == null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => setState(() => _miBosqueActual = null),
                    ),
                  // Avatar con aro estético y zoom al tocar
                  GestureDetector(
                    onTap: () {
                      if (_miBosqueActual?.fotoUrl != null && _miBosqueActual!.fotoUrl!.isNotEmpty) {
                        SupabaseStorageService.mostrarVisorImagen(
                          context,
                          imageUrl: _miBosqueActual!.fotoUrl!,
                          titulo: _miBosqueActual!.nombre,
                        );
                      } else {
                        _mostrarPerfilBosque();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity( 0.85), width: 1.6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity( 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white24,
                        backgroundImage: (_miBosqueActual?.fotoUrl != null && _miBosqueActual!.fotoUrl!.isNotEmpty)
                            ? NetworkImage(_miBosqueActual!.fotoUrl!)
                            : null,
                        child: (_miBosqueActual?.fotoUrl == null || _miBosqueActual!.fotoUrl!.isEmpty)
                            ? const Icon(Icons.forest, color: Colors.white, size: 22)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _mostrarPerfilBosque,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _miBosqueActual?.nombre ?? 'Mi Bosque',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.park, size: 12, color: AppColors.accentYellow),
                                const SizedBox(width: 4),
                                Text(
                                  '${_miembrosDelBosque.length} miembros • Toca para ver perfil',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white, size: 22),
                    tooltip: 'Perfil del Bosque',
                    onPressed: _mostrarPerfilBosque,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _miBosqueActual != null ? _buildForestChat() : const Center(child: Text('No hay bosque seleccionado')),
    );
  }

  void _mostrarPerfilBosque() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_miBosqueActual?.fotoUrl != null && _miBosqueActual!.fotoUrl!.isNotEmpty) {
                            SupabaseStorageService.mostrarVisorImagen(
                              context,
                              imageUrl: _miBosqueActual!.fotoUrl!,
                              titulo: _miBosqueActual!.nombre,
                            );
                          }
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary.withOpacity( 0.1),
                          backgroundImage: (_miBosqueActual?.fotoUrl != null && _miBosqueActual!.fotoUrl!.isNotEmpty)
                              ? NetworkImage(_miBosqueActual!.fotoUrl!)
                              : null,
                          child: (_miBosqueActual?.fotoUrl == null || _miBosqueActual!.fotoUrl!.isEmpty)
                              ? const Icon(Icons.forest, size: 50, color: AppColors.primary)
                              : null,
                        ),
                      ),
                      if (_isCoordinador)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => _cambiarFotoBosque(context),
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.accentYellow,
                              child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_miBosqueActual?.nombre ?? 'Mi Bosque', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_miBosqueActual?.descripcion ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Expanded(
              child: DefaultTabController(
                length: _isCoordinador ? 3 : 1,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: AppColors.primary,
                      indicatorColor: AppColors.primary,
                      isScrollable: _isCoordinador,
                      tabs: [
                        const Tab(text: 'Informacion'),
                        if (_isCoordinador) const Tab(text: 'Ingreso'),
                        if (_isCoordinador) const Tab(text: 'Inscripciones'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildForestProfile(),
                          if (_isCoordinador) _buildRequestsTab(),
                          if (_isCoordinador) _buildInscripcionesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildInscripcionesTab() {
    if (_miBosqueActual == null) return const SizedBox.shrink();

    final eventoService = EventoService();
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    return StreamBuilder<List<InscripcionModel>>(
      stream: eventoService.streamInscripcionesBosque(_miBosqueActual!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final inscripciones = (snapshot.data ?? [])
            .where((i) => i.estado == 'pendiente' || i.estado == 'observada')
            .toList();

        if (inscripciones.isEmpty) {
          return const Center(
            child: Text(
              'No hay inscripciones a eventos pendientes de revision.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Exportar Reporte del Bosque (CSV / Excel)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  onPressed: () async {
                    try {
                      final todosInsc = snapshot.data ?? [];
                      final mockEvento = EventoModel(
                        id: 'bosque_${_miBosqueActual!.id}',
                        titulo: 'Inscripciones - ${_miBosqueActual!.nombre}',
                        descripcion: 'Listado de inscripciones del bosque',
                        lugar: _miBosqueActual!.zona,
                        municipioSede: _miBosqueActual!.zona,
                        tipo: 'municipal',
                        bosquesIds: [_miBosqueActual!.id],
                        fechaInicio: DateTime.now(),
                        fechaFin: DateTime.now(),
                        requiereInscripcion: true,
                        aprobadosCount: todosInsc.where((i) => i.estado == 'aprobada').length,
                        creadoPor: user?.id ?? '',
                        creadorRol: 'coordinador',
                        createdAt: DateTime.now(),
                      );
                      await ReporteService.exportarInscripcionesCsv(
                        evento: mockEvento,
                        inscripciones: todosInsc,
                        nombresBosques: {_miBosqueActual!.id: _miBosqueActual!.nombre},
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
              ),
            ),
            Expanded(
              child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: inscripciones.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final insc = inscripciones[index];
            final esAutoInscripcion = user?.id == insc.uid;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: Text(
                          insc.nombre.isNotEmpty ? insc.nombre[0].toUpperCase() : 'C',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(insc.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Doc: ${insc.documentoId} - ${insc.municipio}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          insc.estado.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (esAutoInscripcion) ...[
                    const Text(
                      'No puedes aprobar tu propia inscripcion; la revisara el Super Admin.',
                      style: TextStyle(fontSize: 12, color: AppColors.error, fontStyle: FontStyle.italic),
                    ),
                  ] else ...[
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

                            if (confirmar == true && user != null) {
                              await eventoService.rechazarInscripcion(
                                inscripcionId: insc.id,
                                motivo: motivoCtrl.text.trim(),
                                revisorId: user.id,
                              );
                            }
                          },
                          child: const Text('Rechazar', style: TextStyle(color: AppColors.error)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () async {
                            if (user == null) return;
                            try {
                              await eventoService.aprobarInscripcion(
                                inscripcionId: insc.id,
                                eventoId: insc.eventoId,
                                revisorId: user.id,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Inscripcion aprobada exitosamente')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
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
            );
          },
        ),
      ),
    ],
  );
},
);
}

  Widget _buildForestProfile() {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Row(
            children: [
              const Icon(Icons.group, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Compañeros del Bosque (${_miembrosDelBosque.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        ..._miembrosDelBosque.map((m) {
          final bool isMe = m.usuarioId == currentUser?.id;
          final campista = _datosCampistas[m.usuarioId];
          final photoUrl = campista?.photoUrl;
          final rango = campista?.rangoDisplay ?? 'Aspirante';
          final nombreCompleto = campista != null ? '${campista.name} ${campista.apellidos}' : m.nombre;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary.withOpacity( 0.07) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isMe ? Border.all(color: AppColors.primary.withOpacity( 0.3)) : Border.all(color: Colors.grey.withOpacity( 0.15)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity( 0.03), blurRadius: 8)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              onTap: () => _mostrarPerfilCampista(m, campista),
              leading: GestureDetector(
                onTap: () {
                  if (photoUrl != null && photoUrl.isNotEmpty) {
                    SupabaseStorageService.mostrarVisorImagen(
                      context,
                      imageUrl: photoUrl,
                      titulo: nombreCompleto,
                    );
                  } else {
                    _mostrarPerfilCampista(m, campista);
                  }
                },
                child: Hero(
                  tag: 'member_avatar_${m.usuarioId}',
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: isMe ? AppColors.primary : const Color(0xFFE8ECE6),
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Icon(
                            m.rol == 'coordinador' ? Icons.military_tech : Icons.person,
                            color: isMe ? Colors.white : AppColors.primary,
                            size: 24,
                          )
                        : null,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      isMe ? '$nombreCompleto (Tú)' : nombreCompleto,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isMe ? AppColors.primary : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (campista?.esArbolMayor == true)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.park, color: Colors.green, size: 16),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: m.rol == 'coordinador' ? const Color(0xFFFFF3CD) : const Color(0xFFD8F3DC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            m.rol == 'coordinador' ? Icons.star : Icons.person,
                            size: 11,
                            color: m.rol == 'coordinador' ? const Color(0xFF856404) : const Color(0xFF1B4332),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            m.rol == 'coordinador' ? 'Coordinador' : 'Campista',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: m.rol == 'coordinador' ? const Color(0xFF856404) : const Color(0xFF1B4332),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ascenso: $rango',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ),
          );
        }).toList(),
        if (_miMembresia != null && !_isCoordinador) ...[
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

  void _mostrarPerfilCampista(MiembroModel m, UserModel? campista) async {
    UserModel? user = campista;
    if (user == null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(m.usuarioId).get();
        if (doc.exists && doc.data() != null) {
          user = UserModel.fromJson({...doc.data()!, 'id': doc.id});
        }
      } catch (_) {}
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
                                SupabaseStorageService.mostrarVisorImagen(
                                  context,
                                  imageUrl: user.photoUrl!,
                                  titulo: '${user.name} ${user.apellidos}',
                                );
                              }
                            },
                            child: Hero(
                              tag: 'campista_${m.usuarioId}',
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2D6A4F), Color(0xFFD4A373)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity( 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 54,
                                  backgroundColor: const Color(0xFFE8ECE6),
                                  backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                                      ? NetworkImage(user.photoUrl!)
                                      : null,
                                  child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                                      ? const Icon(Icons.person, size: 54, color: AppColors.primary)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                            Positioned(
                              bottom: 0,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user != null ? '${user.name} ${user.apellidos}' : m.nombre,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: m.rol == 'coordinador' ? const Color(0xFFFFF3CD) : const Color(0xFFD8F3DC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: m.rol == 'coordinador' ? const Color(0xFFFFC107) : const Color(0xFF52B788),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            m.rol == 'coordinador' ? Icons.military_tech : Icons.verified,
                            size: 14,
                            color: m.rol == 'coordinador' ? const Color(0xFF856404) : const Color(0xFF1B4332),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            m.rol == 'coordinador' ? 'Coordinador del Bosque' : 'Campista Activo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: m.rol == 'coordinador' ? const Color(0xFF856404) : const Color(0xFF1B4332),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tarjeta de Ascenso / Rango
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1B4D3E),
                            Color(0xFF2D6A4F),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B4D3E).withOpacity( 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity( 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.military_tech, color: Color(0xFFFFD166), size: 32),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nivel de Ascenso Campista',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.rangoDisplay ?? 'Aspirante',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (user?.esArbolMayor == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF52B788),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.park, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Árbol Mayor',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Información general del compañero
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información del Campista',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const Divider(height: 20),
                          _buildItemInfo(Icons.location_on, 'Municipio', user?.municipio ?? 'Cundinamarca'),
                          const SizedBox(height: 10),
                          _buildItemInfo(Icons.forest, 'Bosque', _miBosqueActual?.nombre ?? 'Bosque CampJu'),
                          const SizedBox(height: 10),
                          _buildItemInfo(
                            Icons.calendar_today,
                            'En el bosque desde',
                            '${m.fechaIngreso.day}/${m.fechaIngreso.month}/${m.fechaIngreso.year}',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Cursos y Formación del Campista
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.school, size: 20, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'Formación y Cursos CampJu',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildCursoChip(Icons.terrain, 'Campismo Básico', true),
                              _buildCursoChip(Icons.medical_services, 'Primeros Auxilios', true),
                              _buildCursoChip(Icons.explore, 'Orientación y Nudos', user?.rango != 'aspirante'),
                              _buildCursoChip(Icons.groups, 'Liderazgo Juvenil', m.rol == 'coordinador' || user?.esArbolMayor == true),
                              _buildCursoChip(Icons.eco, 'Ecología y Bosques', true),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black54), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildCursoChip(IconData icon, String titulo, bool completado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: completado ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completado ? const Color(0xFFA5D6A7) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: completado ? const Color(0xFF2E7D32) : Colors.grey),
          const SizedBox(width: 6),
          Text(titulo, style: TextStyle(fontSize: 12, fontWeight: completado ? FontWeight.w600 : FontWeight.normal, color: completado ? const Color(0xFF1B5E20) : Colors.grey)),
          const SizedBox(width: 4),
          Icon(
            completado ? Icons.check_circle : Icons.lock_outline,
            size: 13,
            color: completado ? const Color(0xFF2E7D32) : Colors.grey,
          ),
        ],
      ),
    );
  }

  final _chatController = TextEditingController();
  bool _isSendingMedia = false;

  // ─── Foto de perfil del bosque ───
  Future<void> _cambiarFotoBosque(BuildContext ctx) async {
    if (_miBosqueActual == null) return;
    try {
      final url = await SupabaseStorageService.subirFotoBosque(_miBosqueActual!.id);
      if (url == null) return;
      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('bosques')
          .doc(_miBosqueActual!.id)
          .update({'fotoUrl': url});
      // Refrescar datos locales
      await _loadData();
      if (mounted) Navigator.pop(ctx); // Cerrar el perfil
      if (mounted) _mostrarPerfilBosque();  // Volver a abrir con la nueva foto
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir foto: $e'), backgroundColor: Colors.red));
    }
  }

  // ─── Imagen en el chat ───
  Future<void> _adjuntarImagen() async {
    if (_miBosqueActual == null) return;
    setState(() => _isSendingMedia = true);
    try {
      final url = await SupabaseStorageService.subirImagenChat(_miBosqueActual!.id);
      if (url == null) { setState(() => _isSendingMedia = false); return; }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) return;
      final msg = MensajeModel(id: '', senderId: user.id, senderName: user.name, message: 'Foto', timestamp: DateTime.now(), tipo: 'imagen', imageUrl: url);
      await _bosqueService.enviarMensaje(_miBosqueActual!.id, msg);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSendingMedia = false);
    }
  }

  // ─── Archivo en el chat ───
  Future<void> _adjuntarArchivo() async {
    if (_miBosqueActual == null) return;
    setState(() => _isSendingMedia = true);
    try {
      final result = await SupabaseStorageService.subirArchivoChat(_miBosqueActual!.id);
      if (result == null) { setState(() => _isSendingMedia = false); return; }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) return;
      final msg = MensajeModel(id: '', senderId: user.id, senderName: user.name, message: result.nombre, timestamp: DateTime.now(), tipo: 'archivo', imageUrl: result.url, fileName: result.nombre);
      await _bosqueService.enviarMensaje(_miBosqueActual!.id, msg);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSendingMedia = false);
    }
  }

  Widget _buildForestChat() {
    return CampingChatBackground(
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MensajeModel>>(
              stream: _bosqueService.getMensajesStream(_miBosqueActual!.id, limit: _chatLimit),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar mensajes', style: TextStyle(color: Colors.grey)));
                }
                final mensajes = snapshot.data ?? [];
                if (mensajes.isEmpty) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity( 0.85),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity( 0.05), blurRadius: 6),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.forest, size: 36, color: AppColors.primary),
                          SizedBox(height: 6),
                          Text('¡Bienvenidos al Bosque!', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                          SizedBox(height: 2),
                          Text('No hay mensajes aún. ¡Sé el primero en saludar!', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final currentUserId = authProvider.user?.id;
                
                return ListView.builder(
                  controller: _chatScrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    final msg = mensajes[index];
                    final isMe = msg.senderId == currentUserId;
                    final showDate = index == mensajes.length - 1 ||
                        !_isSameDay(msg.timestamp, mensajes[index + 1].timestamp);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showDate) _buildDateSeparator(msg.timestamp),
                        if (msg.tipo == 'sistema_evento')
                          _buildSystemMessageBubble(msg)
                        else
                          _buildMessageBubble(msg, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateSeparator(DateTime dt) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}',
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSystemMessageBubble(MensajeModel msg) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                msg.message,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminarMensaje(MensajeModel msg) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Eliminar mensaje', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(ctx);
                if (_miBosqueActual != null) {
                  try {
                    await _bosqueService.eliminarMensaje(_miBosqueActual!.id, msg.id);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al eliminar mensaje: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MensajeModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          if (isMe || _isCoordinador || _isAdmin) {
            _confirmarEliminarMensaje(msg);
          }
        },
        child: Container(
        margin: const EdgeInsets.only(bottom: 8, top: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity( 0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(msg.senderName, style: const TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            if (msg.tipo == 'imagen' && msg.imageUrl != null) ...[
              GestureDetector(
                onTap: () {
                  SupabaseStorageService.mostrarVisorImagen(
                    context,
                    imageUrl: msg.imageUrl!,
                    titulo: 'Foto de ${msg.senderName}',
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Image.network(
                        msg.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 180,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 14),
                            SizedBox(width: 2),
                            Text('Ver / Descargar', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ] else if (msg.tipo == 'archivo' && msg.imageUrl != null) ...[
              InkWell(
                onTap: () => SupabaseStorageService.abrirODescargarArchivo(
                  context,
                  url: msg.imageUrl!,
                  nombre: msg.fileName,
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white.withOpacity( 0.15) : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.insert_drive_file, color: isMe ? Colors.white : AppColors.primary, size: 30),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.fileName ?? 'Archivo adjunto',
                              style: TextStyle(
                                color: isMe ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Toca para abrir',
                              style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.download, color: isMe ? Colors.white70 : Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ] else ...[
              Text(
                msg.message,
                style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 15),
              ),
              const SizedBox(height: 4),
            ],
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildChatInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isSendingMedia)
          LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.primary.withOpacity( 0.1)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity( 0.05), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: _isSendingMedia ? null : () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                      builder: (_) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(leading: const Icon(Icons.image, color: AppColors.primary), title: const Text('Enviar imagen'), onTap: () { Navigator.pop(context); _adjuntarImagen(); }),
                            ListTile(leading: const Icon(Icons.insert_drive_file, color: AppColors.primary), title: const Text('Enviar archivo'), onTap: () { Navigator.pop(context); _adjuntarArchivo(); }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _chatController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isSendingMedia ? null : _enviarMensajeChat,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _enviarMensajeChat() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _miBosqueActual == null) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    _chatController.clear();
    
    final msg = MensajeModel(
      id: '',
      senderId: user.id,
      senderName: user.name,
      message: text,
      timestamp: DateTime.now(),
    );
    
    try {
      await _bosqueService.enviarMensaje(_miBosqueActual!.id, msg);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
    }
  }
}