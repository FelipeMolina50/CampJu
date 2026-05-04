import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panel Admin', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text('Panel de Administración\n(Users list + promover admin)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

