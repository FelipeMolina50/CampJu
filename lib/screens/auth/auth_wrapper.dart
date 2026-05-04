import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import 'login_screen.dart';
import 'verificar_correo_screen.dart';
import '../home/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        final isAuthenticated = authProvider.isAuthenticated;

        // 1. No autenticado → LoginScreen
        if (!isAuthenticated || user == null) {
          return const LoginScreen();
        }

        // 2. Autenticado pero email no verificado → VerificarCorreoScreen
        if (!user.emailVerified) {
          return const VerificarCorreoScreen();
        }

        // 3. Autenticado y email verificado → HomeScreen
        return const HomeScreen();
      },
    );
  }
}
