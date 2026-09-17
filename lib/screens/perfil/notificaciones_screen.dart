import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../services/auth_provider.dart';
import '../../services/notification_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Configuración local (se puede persistir en Firestore después)
  bool _notifPublicaciones = true;
  bool _notifMensajes = true;
  bool _notifEventos = true;
  bool _notifAnuncios = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              tooltip: 'Marcar todas como leídas',
              onPressed: () => _markAllAsRead(user.id),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.notifications), text: 'Notificaciones'),
            Tab(icon: Icon(Icons.settings), text: 'Configuración'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Listado de notificaciones
          _buildNotificationsList(user?.id),
          // Tab 2: Configuración
          _buildSettingsTab(),
        ],
      ),
    );
  }

  // ── Tab 1: Listado de notificaciones ─────────────────────────────────

  Widget _buildNotificationsList(String? userId) {
    if (userId == null) {
      return const Center(child: Text('Inicia sesión para ver tus notificaciones'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: NotificationService().streamNotifications(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No tienes notificaciones',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data!.docs.map((doc) {
          return NotificationModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return _buildNotificationTile(notif, userId);
          },
        );
      },
    );
  }

  Widget _buildNotificationTile(NotificationModel notif, String userId) {
    final icon = _getIconForType(notif.type);
    final color = _getColorForType(notif.type);
    final timeAgo = _timeAgo(notif.timestamp);

    return Container(
      color: notif.read ? Colors.white : AppColors.primary.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight: notif.read ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notif.body.isNotEmpty)
              Text(
                notif.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            const SizedBox(height: 4),
            Text(
              timeAgo,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: notif.read
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          if (!notif.read) {
            NotificationService().markAsRead(userId, notif.id);
          }
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'publicacion':
        return Icons.article;
      case 'mensaje':
        return Icons.chat_bubble;
      case 'evento':
        return Icons.event;
      case 'sesion':
        return Icons.login;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'publicacion':
        return AppColors.primary;
      case 'mensaje':
        return AppColors.accentBlue;
      case 'evento':
        return AppColors.accentPurple;
      case 'sesion':
        return AppColors.location;
      default:
        return AppColors.textSecondary;
    }
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _markAllAsRead(String userId) {
    NotificationService().markAllAsRead(userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todas las notificaciones marcadas como leídas')),
    );
  }

  // ── Tab 2: Configuración ─────────────────────────────────────────────

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Ajustes de Alertas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Configura qué notificaciones deseas recibir en tu dispositivo.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        _buildToggleItem(
          'Publicaciones del Bosque',
          'Recibe alertas cuando se publique algo nuevo en tu bosque.',
          Icons.article,
          AppColors.primary,
          _notifPublicaciones,
          (v) => setState(() => _notifPublicaciones = v),
        ),
        _buildToggleItem(
          'Mensajes de Chat',
          'Notificaciones de mensajes nuevos en el chat de tu bosque.',
          Icons.chat_bubble,
          AppColors.accentBlue,
          _notifMensajes,
          (v) => setState(() => _notifMensajes = v),
        ),
        _buildToggleItem(
          'Eventos y Actividades',
          'Entérate cuando se programen nuevas actividades.',
          Icons.event,
          AppColors.accentPurple,
          _notifEventos,
          (v) => setState(() => _notifEventos = v),
        ),
        _buildToggleItem(
          'Novedades y Anuncios',
          'Información general de CampJu y actualizaciones.',
          Icons.campaign,
          AppColors.accentYellow,
          _notifAnuncios,
          (v) => setState(() => _notifAnuncios = v),
        ),
      ],
    );
  }

  Widget _buildToggleItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: SwitchListTile(
        secondary: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}
