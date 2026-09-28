import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/bottom_navbar.dart';
import '../../screens/bosque/bosque_screen.dart';
import '../../screens/cursos/cursos_screen.dart';
import '../../screens/perfil/perfil_screen.dart';
import '../../services/auth_provider.dart';

import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static void irATab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_HomeScreenState>();
    if (state != null) {
      state.cambiarTab(index);
    }
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void cambiarTab(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _tabs = [
    const DashboardScreen(),
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
