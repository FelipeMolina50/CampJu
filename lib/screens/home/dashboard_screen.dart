import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_provider.dart';
import '../../services/notification_service.dart';
import '../bosque/widgets/bosque_feed_widget.dart';
import '../bosque/widgets/post_creator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isHeaderExpanded = true;

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
        title: null,
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          // Iconos compactos que aparecen cuando el banner se colapsa
          if (!_isHeaderExpanded) ...[
            _buildAppBarIcon(
              icon: Icons.event_available_outlined,
              tooltip: 'Eventos',
              onTap: () => Navigator.pushNamed(context, AppRoutes.eventos),
            ),
            _buildAppBarNotificationIcon(user?.id),
            _buildAppBarIcon(
              icon: Icons.calendar_month_outlined,
              tooltip: 'Agenda',
              onTap: () => Navigator.pushNamed(context, AppRoutes.agenda),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _handleLogout(context),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            final pixels = notification.metrics.pixels;
            if (pixels > 30 && _isHeaderExpanded) {
              setState(() => _isHeaderExpanded = false);
            } else if (pixels <= 5 && !_isHeaderExpanded) {
              setState(() => _isHeaderExpanded = true);
            }
          }
          return false;
        },
        child: Column(
          children: [
            // Banner expandido con saludo + iconos grandes
            AnimatedCrossFade(
              firstChild: Container(
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
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bienvenido de nuevo a la comunidad CampJu.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
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
              secondChild: const SizedBox.shrink(),
              crossFadeState: _isHeaderExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
            ),
            // Feed de publicaciones
            const Expanded(child: BosqueFeedWidget()),
          ],
        ),
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
              tooltip: 'Crear publicacion',
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // ── Iconos compactos para el AppBar (cuando el banner está colapsado) ──

  Widget _buildAppBarIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 22),
      tooltip: tooltip,
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      constraints: const BoxConstraints(minWidth: 36),
    );
  }

  Widget _buildAppBarNotificationIcon(String? userId) {
    if (userId == null) {
      return _buildAppBarIcon(
        icon: Icons.notifications_outlined,
        tooltip: 'Alertas',
        onTap: () => Navigator.pushNamed(context, AppRoutes.notificaciones),
      );
    }
    return StreamBuilder<int>(
      stream: NotificationService().streamUnreadCount(userId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return IconButton(
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(fontSize: 9, color: Colors.white),
            ),
            backgroundColor: Colors.red,
            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
          ),
          tooltip: 'Alertas',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.notificaciones),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          constraints: const BoxConstraints(minWidth: 36),
        );
      },
    );
  }

  // ── Iconos grandes para el banner expandido ──

  Widget _buildNotificationIcon(BuildContext context, String? userId) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 6),
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
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
