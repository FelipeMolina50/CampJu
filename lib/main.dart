import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_provider.dart';
import 'core/routes/app_routes.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/bosque/bosque_screen.dart';
import 'screens/cursos/cursos_screen.dart';
import 'screens/perfil/perfil_screen.dart';
import 'screens/perfil/editar_perfil_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/terms_conditions_screen.dart';
import 'screens/auth/verificar_correo_screen.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/bosque/bosque_detalle_screen.dart';
import 'screens/cursos/curso_detalle_screen.dart';
import 'services/messaging_service.dart';
import 'screens/bosque/bosque_solicitud_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MessagingService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'CampJu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.verificarCorreo: (context) => const VerificarCorreoScreen(),
          AppRoutes.completeProfile: (context) => const CompleteProfileScreen(),
          AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
          AppRoutes.terms: (context) => const TermsConditionsScreen(),
          AppRoutes.home: (context) => Consumer<AuthProvider>(
            builder: (context, provider, child) => provider.isAuthenticated 
              ? const HomeScreen()
              : const LoginScreen(),
          ),
          AppRoutes.bosque: (context) => Consumer<AuthProvider>(
            builder: (context, provider, child) => provider.isAuthenticated 
              ? const BosqueScreen()
              : const LoginScreen(),
          ),
          AppRoutes.cursos: (context) => Consumer<AuthProvider>(
            builder: (context, provider, child) => provider.isAuthenticated 
              ? const CursosScreen()
              : const LoginScreen(),
          ),
          AppRoutes.perfil: (context) => Consumer<AuthProvider>(
            builder: (context, provider, child) => provider.isAuthenticated 
              ? const PerfilScreen()
              : const LoginScreen(),
          ),
          AppRoutes.editarPerfil: (context) => Consumer<AuthProvider>(
            builder: (context, provider, child) => provider.isAuthenticated 
              ? const EditarPerfilScreen()
              : const LoginScreen(),
          ),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.bosqueDetalle:
              final uri = Uri.parse(settings.name!);
              final id = uri.pathSegments.last;
              return MaterialPageRoute(
                builder: (context) => BosqueDetalleScreen(id: id),
              );
            case AppRoutes.cursoDetalle:
              final uri = Uri.parse(settings.name!);
              final id = uri.pathSegments.last;
              return MaterialPageRoute(
                builder: (context) => CursoDetalleScreen(id: id),
              );
            case AppRoutes.bosqueSolicitud:
              return MaterialPageRoute(
                builder: (context) => const BosqueSolicitudScreen(),
              );
            // Add more
            default:
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                body: Center(child: Text('Route not found: ${settings.name}')),
              ),
              );
          }
        },
      ),
    );
  }
}

