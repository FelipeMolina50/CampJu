import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/publicacion_model.dart';
import '../../../services/auth_provider.dart';
import '../../../services/publicacion_service.dart';
import '../../../services/supabase_storage_service.dart';
import 'comentarios_modal.dart';

class PostCard extends StatelessWidget {
  final PublicacionModel post;
  final String currentUserId;

  const PostCard({
    Key? key,
    required this.post,
    required this.currentUserId,
  }) : super(key: key);

  Future<void> _toggleLike(BuildContext context) async {
    try {
      await PublicacionService().toggleLike(post.id, currentUserId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar me gusta: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _sharePost() {
    final text = 'Mira esta publicacion en CampJu:\n\n${post.titulo}\n\n'
        '${post.mediaUrls.isNotEmpty ? post.mediaUrls.first : ""}';
    Share.share(text);
  }

  void _openMedia(BuildContext context, String url, String type) {
    if (type == 'image') {
      SupabaseStorageService.mostrarVisorImagen(context, imageUrl: url, titulo: post.titulo);
    } else {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final publicacionService = PublicacionService();

    return StreamBuilder<DocumentSnapshot>(
      stream: publicacionService.streamPublicacion(post.id),
      builder: (context, postSnapshot) {
        final postData = postSnapshot.data?.data() as Map<String, dynamic>?;
        final likesCount = postData?['likesCount'] as int? ?? post.likesCount;
        final commentsCount = postData?['commentsCount'] as int? ?? post.commentsCount;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: const Icon(Icons.shield_outlined, color: AppColors.primary),
                ),
                title: Text(
                  post.bosqueNombre,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  _formatDate(post.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: Builder(
                  builder: (ctx) {
                    final currentUser = Provider.of<AuthProvider>(ctx, listen: false).user;
                    final esAutor = currentUser?.id == post.coordinadorId;
                    final esAdmin = currentUser?.role.index == 2;
                    final puedeBorrar = esAutor || esAdmin;

                    if (!puedeBorrar) return const SizedBox.shrink();

                    return PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                      onSelected: (val) async {
                        if (val == 'delete') {
                          final confirmar = await showDialog<bool>(
                            context: ctx,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Eliminar publicacion'),
                              content: const Text('¿Estas seguro de que deseas eliminar esta publicacion? Esta accion no se puede deshacer.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dCtx, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                  onPressed: () => Navigator.pop(dCtx, true),
                                  child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirmar == true) {
                            await PublicacionService().eliminarPublicacion(post.id);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Contenido
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.eventoTitulo != null && post.eventoTitulo!.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_outlined, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              post.eventoTitulo!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Text(
                      post.titulo,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (post.texto != null && post.texto!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        post.texto!,
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Media
              if (post.mediaUrls.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: post.mediaUrls.length,
                    itemBuilder: (context, index) {
                      final url = post.mediaUrls[index];
                      final type = post.mediaTypes[index];

                      return GestureDetector(
                        onTap: () => _openMedia(context, url, type),
                        child: Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                            image: type == 'image'
                                ? DecorationImage(
                                    image: NetworkImage(url),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: type == 'video'
                              ? const Center(
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.play_arrow, color: Colors.white, size: 36),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.border),

              // Acciones
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    // Stream reactivo para el botón de Like
                    StreamBuilder<bool>(
                      stream: publicacionService.streamUserLike(post.id, currentUserId),
                      builder: (context, likeSnapshot) {
                        final isLiked = likeSnapshot.data ?? false;

                        return TextButton.icon(
                          onPressed: () => _toggleLike(context),
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? AppColors.like : AppColors.textSecondary,
                          ),
                          label: Text(
                            '$likesCount',
                            style: TextStyle(
                              color: isLiked ? AppColors.like : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),

                    TextButton.icon(
                      onPressed: () {
                        ComentariosModal.mostrar(
                          context,
                          publicacionId: post.id,
                          autorPublicacionId: post.coordinadorId,
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.textSecondary),
                      label: Text(
                        '$commentsCount',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Spacer(),
                    IconButton(
                      onPressed: _sharePost,
                      icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary),
                      tooltip: 'Compartir',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} horas';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} dias';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
