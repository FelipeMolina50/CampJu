import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_provider.dart';
import '../../services/notification_service.dart';
import '../bosque/widgets/bosque_feed_widget.dart';
import '../bosque/widgets/post_creator.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: null, // Sin título
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _handleLogout(context),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header dinámico sin título "Inicio"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, ${user?.name ?? 'Campista'}!',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bienvenido de nuevo a la comunidad CampJu.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 24),
                // Íconos Módulos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildModuleIcon(
                      context: context,
                      icon: Icons.event_available_outlined,
                      label: 'Eventos',
                      route: AppRoutes.eventos,
                    ),
                    _buildNotificationIcon(context, user?.id),
                    _buildModuleIcon(
                      context: context,
                      icon: Icons.calendar_month_outlined,
                      label: 'Agenda',
                      route: AppRoutes.agenda,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: const BosqueFeedWidget(), // Feed global
          ),
        ],
      ),
      floatingActionButton: (user?.role.index == 1 || user?.role.index == 2) 
          ? FloatingActionButton(
              onPressed: () async {
                String? targetBosqueId = user?.bosqueId; String? bosqueNombre;
                
                // Autosanación para coordinadores antiguos
                if ((targetBosqueId == null || targetBosqueId.isEmpty) && user?.role.index == 1) {
                  try {
                    final query = await FirebaseFirestore.instance
                        .collection('bosques')
                        .where('liderId', isEqualTo: user!.id)
                        .limit(1)
                        .get();
                    if (query.docs.isNotEmpty) {
                      targetBosqueId = query.docs.first.id;
                      bosqueNombre = query.docs.first.data()['nombre'] ?? 'Bosque';
                      // Actualizar su perfil de paso
                      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
                        'bosqueId': targetBosqueId,
                      });
                    }
                  } catch (e) {
                    debugPrint('Error buscando bosque del coordinador: $e');
                  }
                }

                if (!context.mounted) return;

                if (targetBosqueId == null || targetBosqueId.isEmpty) {
                  if (user?.role.index == 2) {
                    // Super‑admin: usar bosque global
                    targetBosqueId = 'global';
                    bosqueNombre = 'Comunidad';
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debes pertenecer a un bosque para crear publicaciones.')),
                    );
                    return;
                  }
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PostCreator(bosqueId: targetBosqueId!, bosqueNombre: bosqueNombre!)),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Crear publicación',
            )
          : null,
    );
  }

  Widget _buildNotificationIcon(BuildContext context, String? userId) {
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.notificaciones),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: userId != null
                ? StreamBuilder<int>(
                    stream: NotificationService().streamUnreadCount(userId),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Badge(
                        isLabelVisible: count > 0,
                        label: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.notifications, color: Colors.white, size: 28),
                      );
                    },
                  )
                : const Icon(Icons.notifications, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Alertas',
          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildModuleIcon({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
