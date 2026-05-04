import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  bool _notifCursos = true;
  bool _notifEventos = true;
  bool _notifMensajes = true;
  bool _notifPromos = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Ajustes de Alertas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 16),
          _buildToggleItem(
            'Progreso de Cursos',
            'Recibe alertas sobre tus avances y nuevos módulos.',
            _notifCursos,
            (v) => setState(() => _notifCursos = v),
          ),
          _buildToggleItem(
            'Eventos de Bosque',
            'Entérate cuando se programen nuevas actividades en tu grupo.',
            _notifEventos,
            (v) => setState(() => _notifEventos = v),
          ),
          _buildToggleItem(
            'Mensajes de Chat',
            'Notificaciones de mensajes nuevos en el chat de tu bosque.',
            _notifMensajes,
            (v) => setState(() => _notifMensajes = v),
          ),
          _buildToggleItem(
            'Novedades y Anuncios',
            'Información general de CampJu y actualizaciones.',
            _notifPromos,
            (v) => setState(() => _notifPromos = v),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}
