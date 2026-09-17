import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/auth_provider.dart';
import '../../../services/admin_service.dart';
import '../../../core/routes/app_routes.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _isLoading = false;

  Future<void> _handleResetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡RESET TOTAL!'),
        content: const Text(
          '¿Estás absolutamente seguro? Esto borrará todos los bosques, miembros, solicitudes y perfiles de usuario (excepto el tuyo). Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SÍ, BORRAR TODO'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final adminService = AdminService();
        await adminService.resetDatabase();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Base de datos reseteada con éxito')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al resetear: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmarEliminarCuenta() async {
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Esta acción es irreversible. Todos tus datos serán eliminados.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text('Ingresa tu contraseña para confirmar:'),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isEmpty) return;

              Navigator.pop(context); // Cerrar diálogo
              setState(() => _isLoading = true);

              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              
              // 1. Re-autenticar
              final successAuth = await authProvider.reauthenticate(password);
              
              if (successAuth) {
                // 2. Eliminar
                final successDelete = await authProvider.deleteAccount();
                if (successDelete && mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(authProvider.errorMessage ?? 'Error al eliminar cuenta')),
                  );
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(authProvider.errorMessage ?? 'Contraseña incorrecta')),
                );
              }

              if (mounted) setState(() => _isLoading = false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Cuenta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Cambiar Correo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implementar cambio de correo
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Cambiar Contraseña'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implementar cambio de contraseña
                },
              ),
              const Divider(height: 32),
              const Text('Preferencias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Modo Oscuro'),
                subtitle: const Text('Próximamente'),
                value: false,
                onChanged: (val) {},
              ),
              SwitchListTile(
                title: const Text('Idioma'),
                subtitle: const Text('Español'),
                value: true,
                onChanged: (val) {},
              ),
              const Divider(height: 32),
              const Text('Zona de Peligro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Eliminar mi cuenta', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Borra permanentemente todos tus datos'),
                onTap: _confirmarEliminarCuenta,
              ),
              if (Provider.of<AuthProvider>(context).user?.email == AppConstants.superAdminEmail) ...[
                const Divider(height: 32),
                const Text('Mantenimiento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.orange),
                  title: const Text('Reset de Fábrica', style: TextStyle(color: Colors.orange)),
                  subtitle: const Text('Borra todo excepto tu cuenta (Uso exclusivo)'),
                  onTap: _handleResetDatabase,
                ),
              ],
            ],
          ),
    );
  }
}
