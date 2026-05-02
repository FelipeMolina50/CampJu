import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../../services/auth_provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final provider = Provider.of<AuthProvider>(context, listen: false);
      final success = await provider.resetPassword(_emailController.text.trim());
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de recuperación enviado. Revisa tu bandeja.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Back to login
      } else {
        final errorCode = provider.errorCode;
        String errorMsg = provider.errorMessage ?? 'Error enviando email. Intenta de nuevo.';
        debugPrint('Reset password error: $errorCode - $errorMsg');

        if (errorCode == 'user-not-found') {
          errorMsg = 'Este correo no está registrado en nuestra base de datos.';
        } else if (errorCode == 'no-password-provider') {
          errorMsg = 'Esta cuenta está registrada con Google. Inicia sesión con Google para acceder.';
        } else if (errorCode == 'invalid-email') {
          errorMsg = 'El formato del correo electrónico no es válido.';
        } else if (errorCode == 'too-many-requests') {
          errorMsg = 'Demasiados intentos. Espera unos minutos antes de intentar nuevamente.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppStyles.paddingH22,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  Icon(
                    Icons.lock_reset_outlined,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ingresa tu email para recibir instrucciones',
                    style: AppStyles.textLg.copyWith(color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    label: 'Correo electrónico',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email obligatorio';
                      }
                      if (!value.contains('@')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    label: _isLoading ? 'Enviando...' : 'Enviar Email',
                    onPressed: _isLoading ? null : _handleReset,
                    isLoading: _isLoading,
                    height: 54,
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Volver al login',
                      style: AppStyles.textBase.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
