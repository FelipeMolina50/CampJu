import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import 'auth_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  
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
      print('Error promover admin: $e');
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
          ...doc.data() as Map<String, dynamic>
        }).toList());
  }
}
