import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class SupabaseStorageService {
  static final _supabase = Supabase.instance.client;
  static const _bucketChat = 'chat-archivos';
  static const _bucketBosques = 'bosques-fotos';
  static const _bucketUsuarios = 'usuarios-fotos';

  static final Set<String> _verifiedBuckets = {};

  static Future<void> _ensureBucket(String bucketId) async {
    if (_verifiedBuckets.contains(bucketId)) return;
    try {
      final buckets = await _supabase.storage.listBuckets();
      final exists = buckets.any((b) => b.id == bucketId);
      if (!exists) {
        await _supabase.storage.createBucket(
          bucketId,
          const BucketOptions(public: true),
        );
      }
      _verifiedBuckets.add(bucketId);
    } catch (e) {
      // Si falla listar/crear (por ejemplo si la key no tiene permisos de admin de buckets), intentamos continuar igual
      _verifiedBuckets.add(bucketId);
    }
  }

  // ──────────────────────────────────────────
  // FOTO DE PERFIL DEL USUARIO
  // ──────────────────────────────────────────

  /// Sube la foto de perfil del usuario (desde archivo o abriendo galería) y devuelve la URL pública.
  static Future<String?> subirFotoUsuario(String userId, {File? file}) async {
    File? archivoASubir = file;
    if (archivoASubir == null) {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null) return null;
      archivoASubir = File(picked.path);
    }

    await _ensureBucket(_bucketUsuarios);

    final ext = p.extension(archivoASubir.path);
    final path = 'usuarios/$userId/perfil$ext';

    await _supabase.storage.from(_bucketUsuarios).upload(
          path,
          archivoASubir,
          fileOptions: const FileOptions(upsert: true),
        );

    // Agregar timestamp para evitar cache en navegadores/móvil al actualizar
    final urlBase = _supabase.storage.from(_bucketUsuarios).getPublicUrl(path);
    return '$urlBase?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  // ──────────────────────────────────────────
  // FOTO DE PERFIL DEL BOSQUE
  // ──────────────────────────────────────────

  /// Abre la galería, sube la imagen y devuelve la URL pública.
  static Future<String?> subirFotoBosque(String bosqueId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return null;

    await _ensureBucket(_bucketBosques);

    final file = File(picked.path);
    final ext = p.extension(picked.path); // .jpg, .png …
    final path = 'bosques/$bosqueId/perfil$ext';

    await _supabase.storage.from(_bucketBosques).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    return _supabase.storage.from(_bucketBosques).getPublicUrl(path);
  }

  // ──────────────────────────────────────────
  // IMÁGENES EN EL CHAT
  // ──────────────────────────────────────────

  /// Abre la galería, sube la imagen al chat y devuelve la URL pública.
  static Future<String?> subirImagenChat(String bosqueId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return null;

    await _ensureBucket(_bucketChat);

    final file = File(picked.path);
    final ext = p.extension(picked.path);
    final nombre = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final path = 'bosques/$bosqueId/$nombre';

    await _supabase.storage.from(_bucketChat).upload(path, file);
    return _supabase.storage.from(_bucketChat).getPublicUrl(path);
  }

  // ──────────────────────────────────────────
  // ARCHIVOS GENERALES EN EL CHAT
  // ──────────────────────────────────────────

  /// Abre el explorador de archivos, sube el archivo y devuelve URL + nombre.
  static Future<({String url, String nombre})?> subirArchivoChat(String bosqueId) async {
    final files = await FilePicker.pickFiles(
      type: FileType.any,
    );
    if (files.isEmpty) return null;

    final archivo = files.first;
    if (archivo.path == null) return null;

    await _ensureBucket(_bucketChat);

    final file = File(archivo.path!);
    final nombre = archivo.name;
    final path = 'bosques/$bosqueId/${DateTime.now().millisecondsSinceEpoch}_$nombre';

    await _supabase.storage.from(_bucketChat).upload(path, file);
    final url = _supabase.storage.from(_bucketChat).getPublicUrl(path);

    return (url: url, nombre: nombre);
  }

  // ──────────────────────────────────────────
  // DESCARGA Y APERTURA DE ARCHIVOS/IMÁGENES
  // ──────────────────────────────────────────
  static Future<void> abrirODescargarArchivo(
    BuildContext context, {
    required String url,
    String? nombre,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Descargando / abriendo ${nombre ?? "archivo"}...')),
    );

    try {
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } catch (_) {}
      }

      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ──────────────────────────────────────────
  // VISOR DE IMAGEN EN PANTALLA COMPLETA
  // ──────────────────────────────────────────
  static void mostrarVisorImagen(
    BuildContext context, {
    required String imageUrl,
    String? titulo,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withOpacity( 0.94),
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image, color: Colors.white60, size: 60),
                          SizedBox(height: 8),
                          Text('No se pudo cargar la imagen', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Barra superior del visor con título y botón de descarga
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        Expanded(
                          child: Text(
                            titulo ?? 'Foto',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.white, size: 28),
                          tooltip: 'Descargar imagen',
                          onPressed: () => abrirODescargarArchivo(
                            context,
                            url: imageUrl,
                            nombre: 'imagen.jpg',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

