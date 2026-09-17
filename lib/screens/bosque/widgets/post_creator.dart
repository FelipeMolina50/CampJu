import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/publicacion_model.dart';
import '../../../services/auth_provider.dart';
import '../../../services/publicacion_service.dart';
import '../../../services/supabase_storage_service.dart';

class PostCreator extends StatefulWidget {
  final String bosqueId;

  const PostCreator({Key? key, required this.bosqueId}) : super(key: key);

  @override
  State<PostCreator> createState() => _PostCreatorState();
}

class _PostCreatorState extends State<PostCreator> {
  final _tituloCtrl = TextEditingController();
  final _textoCtrl = TextEditingController();
  final List<XFile> _selectedMedia = [];
  bool _isUploading = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() => _selectedMedia.addAll(images));
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() => _selectedMedia.add(video));
    }
  }

  void _removeMedia(int index) {
    setState(() => _selectedMedia.removeAt(index));
  }

  Future<void> _submit() async {
    if (_tituloCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título es obligatorio')),
      );
      return;
    }

    setState(() => _isUploading = true);
    
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth!.user!;

      final List<String> urls = [];
      final List<String> types = [];

      // Subir archivos a Supabase
      for (final media in _selectedMedia) {
        final isVideo = media.path.toLowerCase().endsWith('.mp4') || 
                        media.path.toLowerCase().endsWith('.mov');
        
        final url = await SupabaseStorageService.subirMediaPublicacion(
          widget.bosqueId, 
          File(media.path)
        );

        if (url != null) {
          urls.add(url);
          types.add(isVideo ? 'video' : 'image');
        }
      }

      final post = PublicacionModel(
        id: const Uuid().v4(),
        bosqueId: widget.bosqueId,
        coordinadorId: user.id,
        coordinadorNombre: '${user.name} ${user.apellidos}'.trim(),
        titulo: _tituloCtrl.text.trim(),
        texto: _textoCtrl.text.trim().isEmpty ? null : _textoCtrl.text.trim(),
        mediaUrls: urls,
        mediaTypes: types,
        createdAt: DateTime.now(),
      );

      await PublicacionService().crearPublicacion(post);
      
      if (mounted) {
        Navigator.pop(context, true); // Retornar true indica éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Publicación', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Subiendo publicación... esto puede tardar un poco.'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título de la publicación *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textoCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '¿Qué quieres contar a tu bosque? (Opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Añadir Fotos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          foregroundColor: AppColors.primaryDark,
                          elevation: 0,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _pickVideo,
                        icon: const Icon(Icons.videocam),
                        label: const Text('Añadir Video'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          foregroundColor: AppColors.primaryDark,
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_selectedMedia.isNotEmpty) ...[
                    const Text('Archivos seleccionados:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedMedia.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        final isVideo = file.path.toLowerCase().endsWith('.mp4') || 
                                        file.path.toLowerCase().endsWith('.mov');
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                                image: !isVideo
                                    ? DecorationImage(
                                        image: FileImage(File(file.path)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: isVideo
                                  ? const Icon(Icons.videocam, size: 40, color: Colors.grey)
                                  : null,
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _removeMedia(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('PUBLICAR'),
                  ),
                ],
              ),
            ),
    );
  }
}

