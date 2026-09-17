import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_provider.dart';
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
                      icon: Icons.schedule,
                      label: 'Cronograma',
                      route: AppRoutes.cronograma,
                    ),
                    _buildModuleIcon(
                      context: context,
                      icon: Icons.notifications,
                      label: 'Alertas',
                      route: AppRoutes.notificaciones,
                    ),
                    _buildModuleIcon(
                      context: context,
                      icon: Icons.calendar_today,
                      label: 'Calendario',
                      route: AppRoutes.calendario,
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
              onPressed: () {
                if (user?.bosqueId == null || user!.bosqueId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debes pertenecer a un bosque para crear publicaciones.')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PostCreator(bosqueId: user.bosqueId!)),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Crear publicación',
            )
          : null,
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
