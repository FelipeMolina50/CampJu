import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/bottom_navbar.dart';
import '../../screens/bosque/bosque_screen.dart';
import '../../screens/cursos/cursos_screen.dart';
import '../../screens/perfil/perfil_screen.dart';
import '../../services/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Home',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Banner, actividades y novedades pendientes de implementar',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
    const BosqueScreen(),
    const CursosScreen(),
    const PerfilScreen(),
  ];

  void _onTabTap(BuildContext context, int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (index == 3 && user != null && !user.perfilCompleto) {
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Completa tu perfil'),
            content: const Text(
              'Antes de ver tu perfil, debes completar tu información personal. Puedes completar el perfil ahora o regresar al inicio.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Regresar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, AppRoutes.completeProfile);
                },
                child: const Text('Completar ahora'),
              ),
            ],
          );
        },
      );
      return;
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CampJu'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => _onTabTap(context, index),
      ),
    );
  }
}
