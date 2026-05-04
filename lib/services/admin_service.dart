import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Promueve campista a admin (solo superAdmin)
  Future<bool> promoverAdmin(String candidateUid, String currentUserUid) async {
    try {
      // Validar que es superAdmin
      final currentUserDoc = await _firestore.collection('users').doc(currentUserUid).get();
      final currentUserData = currentUserDoc.data();
      if (currentUserData?['email'] != AppConstants.superAdminEmail) {
        throw Exception('Solo el super admin puede promover admins');
      }
      
      // Verificar que no sea admin ya
      if (currentUserData?['role'] == 2) {
        throw Exception('Usuario ya es admin');
      }
      
      // Promover
      await _firestore.collection('users').doc(candidateUid).update({
        'role': 2, // admin
        'updatedAt': DateTime.now(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error promover admin: $e');
      rethrow;
    }
  }
  
  /// Lista todos los usuarios para panel admin
  Stream<List<Map<String, dynamic>>> streamUsers() {
    return _firestore.collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data()
        }).toList());
  }

  /// Obtiene todos los usuarios una vez (útil para dropdowns)
  Future<List<Map<String, dynamic>>> obtenerTodosLosUsuarios() async {
    try {
      final snapshot = await _firestore.collection('users')
          .where('perfilCompleto', isEqualTo: true)
          .get();
      
      final results = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data()
      }).toList();

      results.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      return results;
    } catch (e) {
      debugPrint('Error obtenerTodosLosUsuarios: $e');
      return [];
    }
  }

  /// Obtiene todos los usuarios que pueden ser coordinadores (campistas o coordinadores actuales)
  /// que no tengan un bosque ya asignado.
  Future<List<Map<String, dynamic>>> obtenerCandidatosACoordinador() async {
    try {
      // 1. Obtener todos los usuarios con perfil completo
      final snapshot = await _firestore.collection('users')
          .where('perfilCompleto', isEqualTo: true)
          .get();
      
      final potentialCandidates = snapshot.docs
          .map((doc) => {'uid': doc.id, ...doc.data()})
          .toList();

      // 2. Obtener IDs de líderes que ya tienen bosque para no duplicar
      final bosquesSnapshot = await _firestore.collection('bosques').get();
      final lideresOcupados = bosquesSnapshot.docs
          .map((doc) => doc.data()['liderId'] as String?)
          .where((id) => id != null)
          .toSet();

      // 3. Filtrar disponibles (incluyendo campistas que subirán de rango)
      final disponibles = potentialCandidates
          .where((user) => !lideresOcupados.contains(user['uid']))
          .toList();

      disponibles.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      
      return disponibles;
    } catch (e) {
      debugPrint('Error obtenerCandidatosACoordinador: $e');
      return [];
    }
  }

  Future<void> actualizarUsuario(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error en actualizarUsuario: $e');
      rethrow;
    }
  }
}
