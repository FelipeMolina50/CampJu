import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PrivacidadSeguridadScreen extends StatelessWidget {
  const PrivacidadSeguridadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidad y Seguridad'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Privacidad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 16),
          _buildItem(context, 'Términos y Condiciones', Icons.description_outlined, () {
            // Navigator.pushNamed(context, AppRoutes.terms);
          }),
          _buildItem(context, 'Política de Privacidad', Icons.privacy_tip_outlined, () {}),
          _buildItem(context, 'Gestión de Datos', Icons.data_usage_outlined, () {}),
          const Divider(height: 48),
          const Text('Seguridad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 16),
          _buildItem(context, 'Verificación en dos pasos', Icons.verified_user_outlined, () {}),
          _buildItem(context, 'Dispositivos Activos', Icons.devices_outlined, () {}),
          _buildItem(context, 'Bloqueo de Aplicación', Icons.phonelink_lock_outlined, () {}),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
