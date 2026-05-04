import 'package:firebase_auth/firebase_auth.dart';

class AppConstants {
  // Super Admin - solo tú
  static const String superAdminEmail = 'pipeloco3050@gmail.com';
  
  // Roles
  static bool isSuperAdmin(User? user) {
    return user?.email == superAdminEmail;
  }
  
  static bool isAdmin(User? user) {
    // Verificar role en Firestore también después
    return user != null && isSuperAdmin(user); // Inicialmente solo tú
  }
  
  static String roleDisplay(int roleIndex) {
    const roles = ['Campista', 'Coordinador', 'Admin'];
    return roleIndex < roles.length ? roles[roleIndex] : 'Desconocido';
  }
}
