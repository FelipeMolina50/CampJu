import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onActionTap;

  const MessageBubble({
    super.key,
    required this.message,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final hasAction = message.action != null;

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 56 : 16,
        right: isUser ? 16 : 56,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildBotAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isUser ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppColors.border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
                if (hasAction)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _buildActionButton(message.action!),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Semantics(
      label: 'Avatar del asistente CampJu',
      child: CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.primaryContainer,
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo.png',
            width: 24,
            height: 24,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.smart_toy,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String action) {
    final label = _actionLabel(action);
    final icon = _actionIcon(action);

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onActionTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _actionLabel(String action) {
    return switch (action) {
      'ir_inicio' => 'Ir a Inicio',
      'ir_bosque' => 'Ir a Bosque',
      'ir_cursos' => 'Ir a Cursos',
      'ir_perfil' => 'Ir a Perfil',
      _ => 'Ver más',
    };
  }

  IconData _actionIcon(String action) {
    return switch (action) {
      'ir_inicio' => Icons.home_outlined,
      'ir_bosque' => Icons.forest_outlined,
      'ir_cursos' => Icons.book_outlined,
      'ir_perfil' => Icons.person_outlined,
      _ => Icons.arrow_forward_ios,
    };
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
