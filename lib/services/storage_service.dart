import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload file to bosque folder
  static Future<String> uploadFile(String bosqueId, File file, String fileName) async {
    final ref = _storage.ref().child('bosques/$bosqueId/$fileName');
    final uploadTask = await ref.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  // Upload profile photo
  static Future<String> uploadProfilePhoto(String userId, File photo) async {
    final fileName = 'profiles/$userId/${path.basename(photo.path)}';
    final ref = _storage.ref().child(fileName);
    final uploadTask = await ref.putFile(photo);
    return await uploadTask.ref.getDownloadURL();
  }

  // Get download URL for bosque file
  static Future<String?> getDownloadUrl(String bosqueId, String fileName) async {
    try {
      final ref = _storage.ref().child('bosques/$bosqueId/$fileName');
      return await ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Delete file
  static Future<void> deleteFile(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }
}
