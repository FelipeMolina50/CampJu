import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_provider.dart' as auth_provider;
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final provider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      final success = await provider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (success) {
        // Check if email is verified
        await FirebaseAuth.instance.currentUser?.reload();
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          // Email not verified, redirect to verification screen
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.verificarCorreo,
              (route) => false,
            );
          }
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Bienvenido de vuelta!')),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Error en login')),
        );
      }
    }
  }

  Future<void> _googleSignIn() async {
    // Check if Google Sign-In is supported on this platform
    if (defaultTargetPlatform == TargetPlatform.linux) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In no está disponible en Linux. Usa Android o iOS.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final result = await provider.googleSignIn();
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (result['success'] == true) {
      if (result['isNewUser'] == true) {
        final defaultName = (result['userName'] as String?)?.trim();
        final googleName = await _askNameForNewGoogleUser(defaultName);
        if (!mounted) return;
        if (googleName != null && googleName.trim().isNotEmpty) {
          provider.updateUserName(googleName.trim()).then((saved) {
            if (!saved && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(provider.errorMessage ?? 'No se pudo guardar el nombre')),
              );
            }
          });
        }
      }
      if (!mounted) return;

      // Check if email is verified for Google sign-in
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        // Email not verified, redirect to verification screen
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.verificarCorreo,
            (route) => false,
          );
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Bienvenido con Google!')),
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? provider.errorMessage ?? 'Error Google Sign In')),
      );
    }
  }

  Future<String?> _askNameForNewGoogleUser(String? initialName) async {
    final TextEditingController controller = TextEditingController(text: initialName ?? '');
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Completa tu perfil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Por favor ingresa tu nombre para completar tu perfil.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Omitir'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) {
                      setState(() {
                        errorText = 'El nombre es obligatorio';
                      });
                      return;
                    }
                    Navigator.of(context).pop(value);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation on login screen
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
                padding: AppStyles.paddingH22,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // Título
                    RichText(
                      text: TextSpan(
                        style: AppStyles.text2Xl.copyWith(color: AppColors.textPrimary),
                        children: [
                          const TextSpan(text: 'Bienvenido a '),
                          TextSpan(
                            text: 'CampJu',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Logo
                    Image.asset(
                      'assets/images/logo.png',
                      width: 250,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      label: 'Correo electrónico',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Correo obligatorio';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Contraseña',
                      controller: _passwordController,
                      obscureText: true,
                      prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La contraseña es obligatoria';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Olvidaste contraseña
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.forgotPassword);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: AppStyles.textSm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botón iniciar sesión
                    CustomButton(
                      label: _isLoading ? 'Iniciando...' : 'Iniciar sesión',
                      onPressed: _isLoading ? null : _handleLogin,
                      isLoading: _isLoading,
                      height: 54,
                    ),

                    const SizedBox(height: 24),

                    // Registrarse
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes una cuenta? ',
                          style: AppStyles.textBase.copyWith(color: AppColors.textPrimary),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.register);
                          },
                          child: Text(
                            'Registrarse',
                            style: AppStyles.textBase.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Botón Google Sign In
                    CustomButton(
                      label: 'Continuar con Google',
                      onPressed: _isLoading ? null : _googleSignIn,
                      isLoading: _isLoading,
                      height: 54,
                      backgroundColor: Colors.white,
                      textColor: Colors.black87,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

