import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AyudaSoporteScreen extends StatelessWidget {
  const AyudaSoporteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda y Soporte'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('¿En qué podemos ayudarte?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 24),
          _buildHelpCard(
            context,
            'Preguntas Frecuentes',
            'Encuentra respuestas rápidas a las dudas más comunes.',
            Icons.question_answer_outlined,
          ),
          _buildHelpCard(
            context,
            'Contactar Soporte',
            'Escríbenos directamente si tienes un problema técnico.',
            Icons.support_agent_outlined,
          ),
          _buildHelpCard(
            context,
            'Enviar Comentarios',
            'Tu opinión nos ayuda a mejorar el programa CampJu.',
            Icons.feedback_outlined,
          ),
          const SizedBox(height: 32),
          const Text('Preguntas Destacadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildFaqItem('¿Cómo me uno a un bosque?', 'Ve a la pestaña Bosque, selecciona uno y dale a "Solicitar unirse".'),
          _buildFaqItem('¿Cómo subo de rango?', 'Completando cursos y asistiendo a eventos de tu bosque.'),
          _buildFaqItem('¿Es gratuita la aplicación?', 'Sí, CampJu es una herramienta gratuita para todos los campistas.'),
        ],
      ),
    );
  }

  Widget _buildHelpCard(BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: () {},
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
