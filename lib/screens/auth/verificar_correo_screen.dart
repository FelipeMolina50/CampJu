import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../services/auth_provider.dart' as auth_provider;
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class VerificarCorreoScreen extends StatefulWidget {
  const VerificarCorreoScreen({super.key});

  @override
  State<VerificarCorreoScreen> createState() => _VerificarCorreoScreenState();
}

class _VerificarCorreoScreenState extends State<VerificarCorreoScreen> {
  Timer? _timer;
  Timer? _cooldownTimer;
  bool _isLoading = false;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        _timer?.cancel();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          );
        }
      }
    });
  }

  Future<void> _reenviarCorreo() async {
    if (_resendCooldown > 0) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correo de verificación reenviado. Revisa tu bandeja.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      if (e.code == 'too-many-requests') {
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reenviando correo. Intenta más tarde.')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  void _startCooldown() {
    _resendCooldown = 30;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCooldown -= 1;
      });
      if (_resendCooldown <= 0) {
        timer.cancel();
      }
    });
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'too-many-requests':
        return 'Hemos bloqueado temporalmente los reenvíos de verificación desde este dispositivo debido a actividad inusual. Intenta de nuevo más tarde.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'invalid-email':
        return 'El correo electrónico no tiene un formato válido.';
      case 'network-request-failed':
        return 'Error de red. Revisa tu conexión e intenta nuevamente.';
      default:
        return 'Error reenviando correo: ${e.message ?? e.code}';
    }
  }

  Future<void> _cerrarSesion() async {
    _timer?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    
    // If email is not verified, delete the account
    if (user != null && !user.emailVerified) {
      try {
        await user.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuenta eliminada. Regístrate nuevamente para continuar.')),
          );
        }
      } catch (e) {
        debugPrint('Error deleting unverified account: $e');
      }
    }
    
    final provider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    await provider.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Verificar Correo'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button
      ),
      body: SafeArea(
        child: Padding(
          padding: AppStyles.paddingH22,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verifica tu correo electrónico',
                style: AppStyles.textXl.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Te hemos enviado un correo de verificación a ${FirebaseAuth.instance.currentUser?.email ?? 'tu correo'}. '
                'Haz clic en el enlace del correo para activar tu cuenta.',
                style: AppStyles.textBase.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Verificaremos automáticamente cada 5 segundos. Una vez verificado, entrarás automáticamente.',
                style: AppStyles.textSm.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: _isLoading
                    ? 'Enviando...'
                    : _resendCooldown > 0
                        ? 'Espera ${_resendCooldown}s'
                        : 'Reenviar Correo',
                onPressed: (_isLoading || _resendCooldown > 0) ? null : _reenviarCorreo,
                isLoading: _isLoading,
                height: 54,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _cerrarSesion,
                child: Text(
                  'Cerrar Sesión',
                  style: AppStyles.textBase.copyWith(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}