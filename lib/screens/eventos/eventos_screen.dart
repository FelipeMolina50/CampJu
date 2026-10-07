import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/evento_model.dart';
import '../../models/inscripcion_model.dart';
import '../../services/auth_provider.dart';
import '../../services/evento_service.dart';
import 'evento_detalle_screen.dart';

class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  final EventoService _eventoService = EventoService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final esAdminOCoordinador = user?.role.index == 1 || user?.role.index == 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Eventos y Campamentos'),
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
      body: StreamBuilder<List<EventoModel>>(
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
                  Icon(Icons.event_available_outlined, size: 54, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text(
                    'No hay eventos disponibles para tu bosque.',
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
              return _buildEventoCard(context, ev, user);
            },
          );
        },
      ),
    );
  }

  Widget _buildEventoCard(BuildContext context, EventoModel ev, dynamic user) {
    Color badgeColor = AppColors.primary;
    String badgeText = ev.tipo.toUpperCase();

    if (ev.tipo == 'departamental') {
      badgeColor = AppColors.secondary;
      badgeText = 'DEPARTAMENTAL';
    } else if (ev.tipo == 'nacional') {
      badgeColor = AppColors.accent;
      badgeText = 'NACIONAL';
    }

    final puedeBorrar = (user?.role.index == 2) || (user?.role.index == 1 && ev.creadoPor == user?.id);

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventoDetalleScreen(evento: ev),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${ev.fechaInicio.day}/${ev.fechaInicio.month}/${ev.fechaInicio.year}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                  if (puedeBorrar) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      onPressed: () => _eventoService.eliminarEvento(ev.id),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ev.titulo,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              if (ev.descripcion.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  ev.descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ev.municipioSede.isNotEmpty ? '${ev.lugar} - ${ev.municipioSede}' : ev.lugar,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (ev.cupoTotal != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Cupos: ${ev.aprobadosCount}/${ev.cupoTotal}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ],
              ),
              if (ev.requiereInscripcion) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
                _buildEstadoInscripcionChip(context, ev, user),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoInscripcionChip(BuildContext context, EventoModel ev, dynamic user) {
    if (user == null || user.bosqueId == null || user.bosqueId.isEmpty) {
      return const Text(
        'Debes pertenecer a un bosque para poder inscribirte.',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
      );
    }

    return StreamBuilder<InscripcionModel?>(
      stream: _eventoService.streamMiInscripcion(ev.id, user.id),
      builder: (context, snapshot) {
        final inscripcion = snapshot.data;
        final estado = inscripcion?.estado ?? 'sin_inscribir';

        Color color;
        IconData icon;
        String text;

        switch (estado) {
          case 'aprobada':
            color = AppColors.primary;
            icon = Icons.check_circle;
            text = 'Inscripcion Aprobada';
            break;
          case 'pendiente':
            color = AppColors.accent;
            icon = Icons.schedule;
            text = 'En revision';
            break;
          case 'observada':
            color = Colors.orange;
            icon = Icons.warning_amber_rounded;
            text = 'Documentos observados';
            break;
          case 'rechazada':
            color = AppColors.error;
            icon = Icons.cancel;
            text = 'Inscripcion rechazada';
            break;
          case 'borrador':
            color = Colors.blueGrey;
            icon = Icons.edit_document;
            text = 'Borrador (incompleta)';
            break;
          default:
            color = AppColors.textSecondary;
            icon = Icons.add_circle_outline;
            text = 'Toca para inscribirte';
        }

        return Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        );
      },
    );
  }

  void _mostrarCrearEventoDialog(BuildContext context, dynamic user) {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final lugarCtrl = TextEditingController();
    final cupoCtrl = TextEditingController();
    DateTime fecha = DateTime.now().add(const Duration(days: 3));
    bool requiereInscripcion = true;
    String tipoSeleccionado = user.role.index == 2 ? 'departamental' : 'actividad';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Nuevo Evento o Campamento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: tituloCtrl, decoration: const InputDecoration(labelText: 'Titulo *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  decoration: const InputDecoration(labelText: 'Tipo de Evento', border: OutlineInputBorder()),
                  items: [
                    if (user.role.index == 2) ...[
                      const DropdownMenuItem(value: 'departamental', child: Text('Campamento Departamental')),
                      const DropdownMenuItem(value: 'nacional', child: Text('Campamento Nacional')),
                      const DropdownMenuItem(value: 'interzonal', child: Text('Interzonal')),
                    ],
                    const DropdownMenuItem(value: 'actividad', child: Text('Actividad de Bosque')),
                    const DropdownMenuItem(value: 'campista_dia', child: Text('Campista por un Dia')),
                    const DropdownMenuItem(value: 'municipal', child: Text('Encuentro Municipal')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => tipoSeleccionado = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: lugarCtrl, decoration: const InputDecoration(labelText: 'Lugar / Sede *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                  controller: cupoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cupo Total (Opcional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Requiere inscripcion previa'),
                  value: requiereInscripcion,
                  onChanged: (val) => setDialogState(() => requiereInscripcion = val),
                ),
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
                  tipo: tipoSeleccionado,
                  bosquesIds: (tipoSeleccionado == 'departamental' || tipoSeleccionado == 'nacional')
                      ? []
                      : [user.bosqueId ?? ''],
                  fechaInicio: fecha,
                  fechaFin: fecha.add(const Duration(hours: 6)),
                  requiereInscripcion: requiereInscripcion,
                  cupoTotal: int.tryParse(cupoCtrl.text.trim()),
                  creadoPor: user.id,
                  creadorRol: user.role.index == 2 ? 'admin' : 'coordinador',
                  createdAt: DateTime.now(),
                );

                await _eventoService.crearEvento(nuevoEvento);
              },
              child: const Text('Crear', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
