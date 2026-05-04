import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../models/bosque_model.dart';
import '../../../services/auth_provider.dart';
import '../../../services/bosque_service.dart';
import 'bosque_buscar_screen.dart';
import 'bosque_detalle_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMisBosques();
  }

  Future<void> _loadMisBosques() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        _misBosques = await _bosqueService.obtenerBosques();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando bosques: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _isAdmin {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    return user?.role.index == 2 || AppConstants.isSuperAdmin(firebaseUser);
  }

  void _mostrarCrearBosque() {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final zonaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Crear Bosque'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'Nombre del Bosque *',
                  controller: nombreController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Descripción',
                  controller: descripcionController,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Zona *',
                  controller: zonaController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return CustomButton(
                  label: 'Crear Bosque',
                  onPressed: authProvider.user?.role.index == 2
                      ? () async {
                          Navigator.pop(context);
                          setState(() => _isCreating = true);

                          try {
                            // ✅ Guardamos context antes del gap async
                            final authProv = Provider.of<AuthProvider>(context, listen: false);
                            final user = authProv.user!;
                            final scaffoldMessenger = ScaffoldMessenger.of(context);

                            final bosque = BosqueModel(
                              id: const Uuid().v4(),
                              nombre: nombreController.text.trim(),
                              descripcion: descripcionController.text.trim(),
                              zona: zonaController.text.trim(),
                              liderId: user.id,
                              fotoUrl: null,
                              miembros: 1,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );

                            await _bosqueService.crearBosque(bosque, user.id);

                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(content: Text('¡Bosque creado exitosamente!')),
                              );
                              _loadMisBosques();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isCreating = false);
                            }
                          }
                        }
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Bosques', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _mostrarCrearBosque,
              tooltip: 'Crear Bosque (Solo Admin)',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isCreating
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CustomButton(
                        label: 'Buscar Bosques',
                        onPressed: () async { // ✅ async agregado
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BosqueBuscarScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: _misBosques.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.eco,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No tienes bosques asignados',
                                    style: TextStyle(fontSize: 18, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_isAdmin)
                                    CustomButton(
                                      label: 'Crear Mi Primer Bosque',
                                      onPressed: () async { // ✅ async agregado
                                        _mostrarCrearBosque();
                                      },
                                    ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadMisBosques,
                              child: ListView.builder(
                                itemCount: _misBosques.length,
                                itemBuilder: (context, index) {
                                  final bosque = _misBosques[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.primary,
                                        child: Text(
                                          '${bosque.miembrosCount}',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      title: Text(bosque.nombre, style: AppStyles.heading4),
                                      subtitle: Text(bosque.zona), // ✅ quitado interpolación innecesaria
                                      trailing: CustomButton(
                                        label: 'Detalle',
                                        height: 40,
                                        onPressed: () async { // ✅ async agregado
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => BosqueDetalleScreen(id: bosque.id),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}