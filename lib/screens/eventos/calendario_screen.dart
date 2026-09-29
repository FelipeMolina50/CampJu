import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/evento_model.dart';
import '../../services/auth_provider.dart';
import '../../services/evento_service.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final EventoService _eventoService = EventoService();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final esAdminOCoordinador = user?.role.index == 1 || user?.role.index == 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calendario de Eventos'),
        backgroundColor: AppColors.primary,
        actions: [
          if (esAdminOCoordinador)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Crear Evento',
              onPressed: () => _mostrarCrearEventoDialog(context, user),
            ),
        ],
      ),
      body: Column(
        children: [
          // Selector simple de fecha/días
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (fecha != null) {
                      setState(() => _selectedDate = fecha);
                    }
                  },
                  child: const Text('Cambiar dia', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Lista de eventos filtrados para el usuario
          Expanded(
            child: StreamBuilder<List<EventoModel>>(
              stream: _eventoService.streamEventosUsuario(bosqueId: user?.bosqueId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final eventos = snapshot.data ?? [];

                if (eventos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.event_busy_outlined, size: 54, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text(
                          'No hay eventos programados en este momento.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: eventos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ev = eventos[index];
                    final puedeBorrar = (user?.role.index == 2) || (user?.role.index == 1 && ev.creadoPor == user?.id);
                    final isGlobal = ev.tipo == 'nacional' || ev.tipo == 'departamental' || ev.tipo == 'interzonal';

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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isGlobal ? AppColors.primary.withOpacity(0.12) : AppColors.secondary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isGlobal ? 'Global' : 'Bosque',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isGlobal ? AppColors.primary : AppColors.secondary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${ev.fechaInicio.day}/${ev.fechaInicio.month} - ${ev.fechaInicio.hour.toString().padLeft(2, '0')}:${ev.fechaInicio.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                              ),
                              if (puedeBorrar) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _eventoService.eliminarEvento(ev.id),
                                  child: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            ev.titulo,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          if (ev.descripcion.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              ev.descripcion,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(ev.lugar, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(width: 16),
                              const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(ev.creadorRol.toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarCrearEventoDialog(BuildContext context, dynamic user) {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final lugarCtrl = TextEditingController();
    DateTime fecha = DateTime.now().add(const Duration(days: 1));
    String scope = user.role.index == 2 ? 'global' : 'bosque';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Evento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: tituloCtrl, decoration: const InputDecoration(labelText: 'Titulo del Evento *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: lugarCtrl, decoration: const InputDecoration(labelText: 'Lugar / Enlace *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Descripcion', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (tituloCtrl.text.trim().isEmpty || lugarCtrl.text.trim().isEmpty) return;

              Navigator.pop(ctx);

              final nuevoEvento = EventoModel(
                id: '',
                titulo: tituloCtrl.text.trim(),
                descripcion: descCtrl.text.trim(),
                lugar: lugarCtrl.text.trim(),
                tipo: scope == 'global' ? 'nacional' : 'actividad',
                bosquesIds: scope == 'bosque' && user.bosqueId != null ? [user.bosqueId!] : [],
                fechaInicio: fecha,
                fechaFin: fecha.add(const Duration(hours: 2)),
                creadoPor: user.id,
                creadorRol: user.role.index == 2 ? 'admin' : 'coordinador',
                createdAt: DateTime.now(),
              );

              await _eventoService.crearEvento(nuevoEvento);
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
