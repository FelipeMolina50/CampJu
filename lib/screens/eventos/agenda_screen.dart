import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/evento_model.dart';
import '../../services/auth_provider.dart';
import '../../services/evento_service.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final eventoService = EventoService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Agenda Confirmada'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<List<EventoModel>>(
        stream: eventoService.streamEventosUsuario(bosqueId: user?.bosqueId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final todosEventos = snapshot.data ?? [];

          return StreamBuilder(
            stream: (user != null && user.bosqueId != null)
                ? eventoService.streamInscripcionesBosque(user.bosqueId!)
                : null,
            builder: (ctx, inscSnap) {
              final misInscripciones = (inscSnap.data ?? [])
                  .where((i) => i.uid == user?.id && i.estado == 'aprobada')
                  .map((i) => i.eventoId)
                  .toSet();

              // Agenda muestra:
              // 1. Eventos sin inscripción de su bosque
              // 2. Eventos con inscripción aprobada
              // 3. Eventos creados por el propio coordinador
              final eventosConfirmados = todosEventos.where((ev) {
                if (ev.creadoPor == user?.id) return true;
                if (!ev.requiereInscripcion) return true;
                if (misInscripciones.contains(ev.id)) return true;
                return false;
              }).toList();

              if (eventosConfirmados.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.event_note_outlined, size: 54, color: AppColors.textSecondary),
                      SizedBox(height: 12),
                      Text(
                        'No tienes eventos confirmados en tu agenda aun.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Los campamentos apareceran aqui una vez tu inscripcion sea aprobada.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: eventosConfirmados.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ev = eventosConfirmados[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'CONFIRMADO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${ev.fechaInicio.day}/${ev.fechaInicio.month}/${ev.fechaInicio.year}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ev.titulo,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(ev.lugar, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
