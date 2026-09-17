import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class SupabaseStorageService {
  static final _supabase = Supabase.instance.client;
  static const _bucketChat = 'chat-archivos';
  static const _bucketBosques = 'bosques-fotos';

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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final archivo = result.files.first;
    if (archivo.path == null) return null;

    await _ensureBucket(_bucketChat);

    final file = File(archivo.path!);
    final nombre = archivo.name;
    final path = 'bosques/$bosqueId/${DateTime.now().millisecondsSinceEpoch}_$nombre';

    await _supabase.storage.from(_bucketChat).upload(path, file);
    final url = _supabase.storage.from(_bucketChat).getPublicUrl(path);

    return (url: url, nombre: nombre);
  }
}

