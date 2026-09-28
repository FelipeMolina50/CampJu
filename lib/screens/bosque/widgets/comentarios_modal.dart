import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/comentario_model.dart';
import '../../../../services/auth_provider.dart';
import '../../../../services/publicacion_service.dart';

class ComentariosModal extends StatefulWidget {
  final String publicacionId;
  final String autorPublicacionId;

  const ComentariosModal({
    Key? key,
    required this.publicacionId,
    required this.autorPublicacionId,
  }) : super(key: key);

  static void mostrar(BuildContext context, {required String publicacionId, required String autorPublicacionId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ComentariosModal(
        publicacionId: publicacionId,
        autorPublicacionId: autorPublicacionId,
      ),
    );
  }

  @override
  State<ComentariosModal> createState() => _ComentariosModalState();
}

class _ComentariosModalState extends State<ComentariosModal> {
  final TextEditingController _commentCtrl = TextEditingController();
  final PublicacionService _publicacionService = PublicacionService();
  bool _isSending = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarComentario() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      final nuevoComentario = ComentarioModel(
        id: '',
        publicacionId: widget.publicacionId,
        usuarioId: user.id,
        usuarioNombre: '${user.name} ${user.apellidos}'.trim(),
        texto: text,
        createdAt: DateTime.now(),
      );

      await _publicacionService.agregarComentario(nuevoComentario);
      _commentCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar comentario: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _eliminarComentario(String comentarioId) async {
    try {
      await _publicacionService.eliminarComentario(widget.publicacionId, comentarioId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar comentario: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} horas';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Barra de arrastre superior
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titulo del modal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Comentarios',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Lista de comentarios en tiempo real
          Expanded(
            child: StreamBuilder<List<ComentarioModel>>(
              stream: _publicacionService.getComentariosStream(widget.publicacionId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comentarios = snapshot.data ?? [];

                if (comentarios.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.speaker_notes_off_outlined, size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 8),
                        Text(
                          'Aun no hay comentarios. Se el primero en opinar.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comentarios.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final c = comentarios[index];
                    final esAutorComentario = user?.id == c.usuarioId;
                    final esAdminOCoordinador = user?.role.index == 1 || user?.role.index == 2;
                    final puedeBorrar = esAutorComentario || esAdminOCoordinador;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primary.withOpacity(0.15),
                                child: Text(
                                  c.usuarioNombre.isNotEmpty ? c.usuarioNombre[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.usuarioNombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                _formatDate(c.createdAt),
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              if (puedeBorrar) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _eliminarComentario(c.id),
                                  child: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 36),
                            child: Text(
                              c.texto,
                              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Campo de entrada para redactar comentario
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario...',
                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: AppColors.primary),
                        onPressed: _enviarComentario,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
