import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

/// Servicio centralizado para operaciones de almacenamiento con Supabase Storage.
///
/// Todos los buckets están marcados como PUBLIC con RLS activado.
/// Las políticas requieren usuario autenticado para INSERT/UPDATE/DELETE.
///
/// Buckets disponibles:
///   - [bucketChat]     → archivos e imágenes del chat grupal
///   - [bucketBosques]  → fotos de perfil de bosques
///   - [bucketUsuarios] → fotos de perfil de usuarios
///   - [bucketMedia]    → media general de publicaciones del feed
class SupabaseStorageService {
  // ──────────────────────────────────────────
  // CONSTANTES DE BUCKETS
  // ──────────────────────────────────────────
  static const bucketChat = 'chat-archivos';
  static const bucketBosques = 'bosques-fotos';
  static const bucketUsuarios = 'usuarios-fotos';
  static const bucketMedia = 'campju-media';
  static const bucketInscripciones = 'inscripciones-documentos';

  /// Limite maximo de archivo para subidas al chat (10 MB).
  static const _maxFileSizeBytes = 10 * 1024 * 1024;

  static SupabaseClient get _client => Supabase.instance.client;

  // ──────────────────────────────────────────
  // GUARD DE AUTENTICACION
  // ──────────────────────────────────────────

  /// Verifica que exista una sesion activa en Firebase antes de cualquier operacion.
  /// Lanza [StorageException] si no hay usuario autenticado.
  static void _requireAuth() {
    if (fb.FirebaseAuth.instance.currentUser == null) {
      throw const StorageException(
        'Se requiere iniciar sesion para realizar esta operacion.',
      );
    }
  }

  // ──────────────────────────────────────────
  // CORE: SUBIDA DE ARCHIVOS (REUTILIZABLE)
  // ──────────────────────────────────────────

  /// Sube un archivo a un bucket de Supabase Storage y devuelve la URL publica.
  ///
  /// - [bucket]: nombre del bucket destino.
  /// - [path]: ruta relativa dentro del bucket (ej: 'usuarios/abc123/perfil.jpg').
  /// - [file]: archivo a subir.
  /// - [cacheBust]: si es true, agrega un timestamp a la URL para invalidar cache.
  ///
  /// Lanza [StorageException] si el usuario no esta autenticado o si Supabase
  /// rechaza la operacion (permisos, tamaño, etc).
  static Future<String> _uploadFile({
    required String bucket,
    required String path,
    required File file,
    bool cacheBust = false,
  }) async {
    _requireAuth();

    try {
      await _client.storage.from(bucket).upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _client.storage.from(bucket).getPublicUrl(path);
      return cacheBust ? '$url?t=${DateTime.now().millisecondsSinceEpoch}' : url;
    } on StorageException catch (e) {
      debugPrint('[StorageService] StorageException en $bucket/$path: '
          '${e.statusCode} – ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[StorageService] Error inesperado subiendo a $bucket/$path: $e');
      throw StorageException('Error al subir archivo: $e');
    }
  }

  /// Genera un nombre de archivo unico usando timestamp + extension original.
  static String _uniqueName(String originalPath) {
    final ext = p.extension(originalPath); // .jpg, .png, .pdf …
    return '${DateTime.now().millisecondsSinceEpoch}$ext';
  }

  // ──────────────────────────────────────────
  // CORE: ELIMINACION DE ARCHIVOS
  // ──────────────────────────────────────────

  /// Elimina un archivo del bucket indicado.
  ///
  /// - [bucket]: nombre del bucket (actualmente solo [bucketChat] tiene politica DELETE).
  /// - [path]: ruta relativa del archivo dentro del bucket.
  ///
  /// Ejemplo:
  /// ```dart
  /// await SupabaseStorageService.eliminarArchivo(
  ///   SupabaseStorageService.bucketChat,
  ///   'bosques/abc123/1719600000000.jpg',
  /// );
  /// ```
  static Future<void> eliminarArchivo(String bucket, String path) async {
    _requireAuth();

    try {
      await _client.storage.from(bucket).remove([path]);
    } on StorageException catch (e) {
      debugPrint('[StorageService] Error eliminando $bucket/$path: '
          '${e.statusCode} – ${e.message}');
      rethrow;
    }
  }

  /// Extrae la ruta relativa de un archivo dentro de un bucket a partir de su URL publica.
  ///
  /// Util para obtener el path necesario para [eliminarArchivo].
  /// Retorna `null` si la URL no pertenece al bucket indicado.
  static String? extraerPathDeUrl(String bucket, String url) {
    // URL tipica: https://<proyecto>.supabase.co/storage/v1/object/public/<bucket>/<path>
    final marker = '/storage/v1/object/public/$bucket/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;

    String path = url.substring(idx + marker.length);
    // Remover query params (?t=..., &download=...)
    final qIdx = path.indexOf('?');
    if (qIdx != -1) path = path.substring(0, qIdx);
    return path;
  }

  // ══════════════════════════════════════════
  //  METODOS DE DOMINIO
  // ══════════════════════════════════════════

  // ──────────────────────────────────────────
  // FOTO DE PERFIL DEL USUARIO
  // ──────────────────────────────────────────

  /// Sube la foto de perfil del usuario y devuelve la URL publica.
  ///
  /// Si no se proporciona [file], abre la galeria para que el usuario seleccione.
  /// Retorna `null` si el usuario cancela la seleccion.
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

    final ext = p.extension(archivoASubir.path);
    final path = 'usuarios/$userId/perfil$ext';

    return _uploadFile(
      bucket: bucketUsuarios,
      path: path,
      file: archivoASubir,
      cacheBust: true, // Evitar cache al actualizar foto de perfil
    );
  }

  // ──────────────────────────────────────────
  // FOTO DE PERFIL DEL BOSQUE
  // ──────────────────────────────────────────

  /// Abre la galeria, sube la foto de perfil del bosque y devuelve la URL publica.
  /// Retorna `null` si el usuario cancela la seleccion.
  static Future<String?> subirFotoBosque(String bosqueId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return null;

    final ext = p.extension(picked.path);
    final path = 'bosques/$bosqueId/perfil$ext';

    return _uploadFile(
      bucket: bucketBosques,
      path: path,
      file: File(picked.path),
      cacheBust: true,
    );
  }

  // ──────────────────────────────────────────
  // IMAGENES EN EL CHAT
  // ──────────────────────────────────────────

  /// Abre la galeria, sube la imagen al chat y devuelve la URL publica.
  /// Retorna `null` si el usuario cancela la seleccion.
  static Future<String?> subirImagenChat(String bosqueId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return null;

    final nombre = _uniqueName(picked.path);
    final path = 'bosques/$bosqueId/$nombre';

    return _uploadFile(
      bucket: bucketChat,
      path: path,
      file: File(picked.path),
    );
  }

  // ──────────────────────────────────────────
  // ARCHIVOS GENERALES EN EL CHAT
  // ──────────────────────────────────────────

  /// Abre el explorador de archivos, sube el archivo al chat y devuelve URL + nombre.
  ///
  /// Lanza [Exception] si el archivo excede [_maxFileSizeBytes] (10 MB).
  /// Retorna `null` si el usuario cancela la seleccion.
  static Future<({String url, String nombre})?> subirArchivoChat(String bosqueId) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return null;

    final archivo = result.files.first;
    if (archivo.path == null) return null;

    if (archivo.size > _maxFileSizeBytes) {
      throw Exception(
        'El archivo seleccionado supera el limite maximo permitido de 10 MB.',
      );
    }

    final nombre = archivo.name;
    final path = 'bosques/$bosqueId/${DateTime.now().millisecondsSinceEpoch}_$nombre';

    final url = await _uploadFile(
      bucket: bucketChat,
      path: path,
      file: File(archivo.path!),
    );

    return (url: url, nombre: nombre);
  }

  // ──────────────────────────────────────────
  // MEDIA DE PUBLICACIONES DEL FEED
  // ──────────────────────────────────────────

  /// Sube un archivo multimedia (imagen o video) de una publicacion del feed.
  ///
  /// Utiliza el bucket [bucketMedia] ('campju-media').
  /// Retorna la URL publica o `null` si ocurre un error controlado.
  static Future<String?> subirMediaPublicacion(String bosqueId, File file) async {
    final nombre = _uniqueName(file.path);
    final path = 'bosques/$bosqueId/publicaciones/$nombre';

    try {
      return await _uploadFile(
        bucket: bucketMedia,
        path: path,
        file: file,
      );
    } on StorageException catch (e) {
      debugPrint('[StorageService] Error subiendo media de publicacion: '
          '${e.statusCode} – ${e.message}');
      return null;
    }
  }

  // ══════════════════════════════════════════
  //  UTILIDADES DE UI
  // ══════════════════════════════════════════

  // ──────────────────────────────────────────
  // DESCARGA Y APERTURA DE ARCHIVOS/IMAGENES
  // ──────────────────────────────────────────

  /// Abre un archivo o imagen en el navegador/app externa para descarga.
  static Future<void> abrirODescargarArchivo(
    BuildContext context, {
    required String url,
    String? nombre,
  }) async {
    final String finalUrl = url.contains('?') ? '$url&download=' : '$url?download=';
    final uri = Uri.tryParse(finalUrl);
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
          SnackBar(
            content: Text('Error al abrir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ──────────────────────────────────────────
  // VISOR DE IMAGEN EN PANTALLA COMPLETA
  // ──────────────────────────────────────────

  /// Muestra una imagen en pantalla completa con zoom interactivo y opcion de descarga.
  static void mostrarVisorImagen(
    BuildContext context, {
    required String imageUrl,
    String? titulo,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.94),
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
                          Text(
                            'No se pudo cargar la imagen',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Barra superior del visor con titulo y boton de descarga
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

  // ──────────────────────────────────────────
  // DOMINIO: INSCRIPCIONES (BUCKET PRIVADO)
  // ──────────────────────────────────────────

  static Future<String> subirDocumentoInscripcion({
    required File file,
    required String eventoId,
    required String uid,
    required String docId,
    required String extension,
  }) async {
    _requireAuth();
    final path = '$eventoId/$uid/$docId.$extension';
    try {
      await _client.storage.from(bucketInscripciones).upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      return path;
    } on StorageException catch (e) {
      throw StorageException('Error Supabase al subir documento: ${e.message}');
    } catch (e) {
      throw StorageException('Error inesperado al subir documento: $e');
    }
  }

  static Future<String> obtenerUrlFirmada(String path) async {
    _requireAuth();
    try {
      final url = await _client.storage.from(bucketInscripciones).createSignedUrl(
        path,
        300,
      );
      return url;
    } catch (e) {
      throw StorageException('Error obteniendo URL firmada: $e');
    }
  }
}
