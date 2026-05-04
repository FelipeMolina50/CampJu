import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_provider.dart' as auth_provider;
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final TapGestureRecognizer _termsRecognizer = TapGestureRecognizer();
  bool _isLoading = false;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Debes aceptar los Términos y Condiciones para continuar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if ((_formKey.currentState?.validate() ?? false)) {
      setState(() {
        _isLoading = true;
      });
      final provider =
          Provider.of<auth_provider.AuthProvider>(context, listen: false);
      final success = await provider.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      if (!mounted) return;
      if (success) {
        // Check if email is verified
        await FirebaseAuth.instance.currentUser?.reload();
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          // Navigate to verification screen
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.verificarCorreo,
              (route) => false,
            );
          }
        } else {
          // Email already verified, go through AuthWrapper to enforce profile completion
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Error en registro')),
        );
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white),
                      const SizedBox(width: 5),
                      Text("Volver", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Crear Cuenta",
                  style: const TextStyle(color: Colors.white, fontSize: 28),
                ),
                Text(
                  "Únete a la comunidad CampuJu",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Nombre completo',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nombre obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      label: 'Correo electrónico',
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Correo obligatorio';
                        }
                        if (!value.trim().contains('@')) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    CustomTextField(
                      label: 'Contraseña',
                      obscureText: true,
                      controller: _passwordController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Contraseña obligatoria';
                        }
                        if (value.trim().length < 8) {
                          return 'Mínimo 8 caracteres';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    CustomTextField(
                      label: 'Confirmar contraseña',
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Confirmar contraseña obligatoria';
                        }
                        if (value.trim() != _passwordController.text.trim()) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text.rich(
                        TextSpan(
                          text: 'He leído y acepto los ',
                          style: const TextStyle(fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Términos y Condiciones',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: _termsRecognizer
                                ..onTap = () {
                                  Navigator.pushNamed(context, AppRoutes.terms);
                                },
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      value: _termsAccepted,
                      onChanged: (value) =>
                          setState(() => _termsAccepted = value ?? false),
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(height: 20),

                    // BUTTON
                    CustomButton(
                      label: _isLoading ? 'Creando...' : 'Crear Cuenta',
                      onPressed: _isLoading ? null : _handleRegister,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.login),
                      child: const Text("¿Ya tienes cuenta? Inicia sesión"),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
