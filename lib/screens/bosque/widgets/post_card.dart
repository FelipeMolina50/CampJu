import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/publicacion_model.dart';
import '../../../services/publicacion_service.dart';
import '../../../services/supabase_storage_service.dart';

class PostCard extends StatefulWidget {
  final PublicacionModel post;
  final String currentUserId;

  const PostCard({Key? key, required this.post, required this.currentUserId}) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isLoadingLike = true;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final liked = await PublicacionService().haDadoLike(widget.post.id, widget.currentUserId);
    if (mounted) {
      setState(() {
        _isLiked = liked;
        _isLoadingLike = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoadingLike) return;
    
    // UI optimista
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      final isNowLiked = await PublicacionService().toggleLike(widget.post.id, widget.currentUserId);
      if (mounted && _isLiked != isNowLiked) {
        // Revertir si el server devolvió algo diferente
        setState(() {
          _isLiked = isNowLiked;
          _likesCount = widget.post.likesCount + (isNowLiked ? 1 : 0);
        });
      }
    } catch (e) {
      // Revertir en caso de error
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? 1 : -1;
        });
      }
    }
  }

  void _sharePost() {
    final text = '¡Mira esta publicación en CampJu!\n\n${widget.post.titulo}\n\n'
        '${widget.post.mediaUrls.isNotEmpty ? widget.post.mediaUrls.first : ""}';
    Share.share(text);
  }

  void _openMedia(String url, String type) {
    if (type == 'image') {
      SupabaseStorageService.mostrarVisorImagen(context, imageUrl: url, titulo: widget.post.titulo);
    } else {
      // Para video, abrimos en el navegador/app externa por simplicidad y compatibilidad
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.military_tech, color: AppColors.primaryDark),
            ),
            title: Text(
              widget.post.coordinadorNombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Coordinador del Bosque • ${_formatDate(widget.post.createdAt)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.titulo,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (widget.post.texto != null && widget.post.texto!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.post.texto!,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Media
          if (widget.post.mediaUrls.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.post.mediaUrls.length,
                itemBuilder: (context, index) {
                  final url = widget.post.mediaUrls[index];
                  final type = widget.post.mediaTypes[index];
                  
                  return GestureDetector(
                    onTap: () => _openMedia(url, type),
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
                                radius: 30,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.play_arrow, color: Colors.white, size: 40),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            
          const SizedBox(height: 8),
          const Divider(height: 1),
          
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _toggleLike,
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.grey[600],
                  ),
                  label: Text(
                    '$_likesCount',
                    style: TextStyle(
                      color: _isLiked ? Colors.red : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implementar vista de comentarios
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comentarios próximamente')),
                    );
                  },
                  icon: Icon(Icons.chat_bubble_outline, color: Colors.grey[600]),
                  label: Text(
                    '${widget.post.commentsCount}',
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _sharePost,
                  icon: Icon(Icons.share, color: Colors.grey[600]),
                  tooltip: 'Compartir',
                ),
              ],
            ),
          ),
        ],
      ),
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
      return 'Hace ${diff.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

