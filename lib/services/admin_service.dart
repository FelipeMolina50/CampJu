import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import 'auth_service.dart';
import 'bosque_service.dart';
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

  /// LIMPIEZA TOTAL: Borra bosques, miembros, solicitudes y usuarios (excepto superAdmin)
  Future<void> resetDatabase() async {
    try {
      // 1. Borrar Bosques
      final bosques = await _firestore.collection('bosques').get();
      for (var doc in bosques.docs) {
        await doc.reference.delete();
      }

      // 2. Borrar Miembros
      final miembros = await _firestore.collection('miembros').get();
      for (var doc in miembros.docs) {
        await doc.reference.delete();
      }

      // 3. Borrar Solicitudes
      final solicitudes = await _firestore.collection('solicitudes').get();
      for (var doc in solicitudes.docs) {
        await doc.reference.delete();
      }

      // 4. Borrar Usuarios (EXCEPTO Super Admin)
      final usuarios = await _firestore.collection('users').get();
      for (var doc in usuarios.docs) {
        final data = doc.data();
        if (data['email'] != AppConstants.superAdminEmail) {
          await doc.reference.delete();
        } else {
          // Limpiar el bosqueId del super admin también
          await doc.reference.update({
            'bosqueId': null,
            'fechaIngresoBosque': null,
            'role': 2, // Asegurar que sigue siendo Admin
          });
        }
      }
      debugPrint('Reset de base de datos completado con éxito');
    } catch (e) {
      debugPrint('Error en resetDatabase: $e');
      rethrow;
    }
  }

  Future<void> eliminarBosque(String bosqueId, String email) async {
    try {
      final bosqueService = BosqueService();
      await bosqueService.eliminarBosque(bosqueId, email);
    } catch (e) {
      debugPrint('Error en eliminarBosque admin: $e');
      rethrow;
    }
  }
}
