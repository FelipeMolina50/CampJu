import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/evento_model.dart';
import '../../models/inscripcion_model.dart';
import '../../services/auth_provider.dart';
import '../../services/evento_service.dart';
import 'inscripcion_documentos_screen.dart';

class EventoDetalleScreen extends StatefulWidget {
  final EventoModel evento;

  const EventoDetalleScreen({super.key, required this.evento});

  @override
  State<EventoDetalleScreen> createState() => _EventoDetalleScreenState();
}

class _EventoDetalleScreenState extends State<EventoDetalleScreen> {
  final EventoService _eventoService = EventoService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle del Evento'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<InscripcionModel?>(
        stream: user != null ? _eventoService.streamMiInscripcion(widget.evento.id, user.id) : const Stream.empty(),
        builder: (context, snapshot) {
          final inscripcion = snapshot.data;
          final estado = inscripcion?.estado ?? 'sin_inscribir';
          
          final ahora = DateTime.now();
          final cerradoPorFecha = widget.evento.fechaLimiteInscripcion != null && 
                                   ahora.isAfter(widget.evento.fechaLimiteInscripcion!);
          final sinCupos = widget.evento.cupoTotal != null && 
                           widget.evento.aprobadosCount >= widget.evento.cupoTotal!;
          final cerrado = widget.evento.estado == 'cerrado' || widget.evento.estado == 'cancelado';
          final noPuedeInscribirse = cerrado || cerradoPorFecha || sinCupos;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildInfoCard(cerradoPorFecha, sinCupos),
                const SizedBox(height: 20),
                if (widget.evento.requiereInscripcion) ...[
                  _buildRequisitosCard(),
                  const SizedBox(height: 24),
                  _buildBotonInscripcion(context, estado, noPuedeInscribirse, user, inscripcion),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    Color badgeColor = AppColors.primary;
    String badgeText = widget.evento.tipo.toUpperCase();

    if (widget.evento.tipo == 'departamental') {
      badgeColor = AppColors.secondary;
      badgeText = 'DEPARTAMENTAL';
    } else if (widget.evento.tipo == 'nacional') {
      badgeColor = AppColors.accent;
      badgeText = 'NACIONAL';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badgeText,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.evento.titulo,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        if (widget.evento.descripcion.isNotEmpty)
          Text(
            widget.evento.descripcion,
            style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
      ],
    );
  }

  Widget _buildInfoCard(bool cerradoPorFecha, bool sinCupos) {
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
          _buildInfoRow(Icons.calendar_today, 'Inicio: ${_formatDate(widget.evento.fechaInicio)}'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.event_busy, 'Fin: ${_formatDate(widget.evento.fechaFin)}'),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.place_outlined,
            widget.evento.municipioSede.isNotEmpty 
                ? '${widget.evento.lugar} - ${widget.evento.municipioSede}' 
                : widget.evento.lugar,
          ),
          if (widget.evento.cupoTotal != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.group_outlined,
              'Cupos: ${widget.evento.aprobadosCount} / ${widget.evento.cupoTotal}',
              color: sinCupos ? AppColors.error : AppColors.textSecondary,
            ),
          ],
          if (widget.evento.fechaLimiteInscripcion != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.timer_off_outlined,
              'Cierre inscripciones: ${_formatDate(widget.evento.fechaLimiteInscripcion!)}',
              color: cerradoPorFecha ? AppColors.error : AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 15, color: color ?? AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildRequisitosCard() {
    if (widget.evento.documentosRequeridos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentos requeridos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: widget.evento.documentosRequeridos.map((doc) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.attach_file, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${doc.nombre}${doc.obligatorio ? " *" : ""}',
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonInscripcion(
    BuildContext context, 
    String estado, 
    bool noPuedeInscribirse, 
    dynamic user, 
    InscripcionModel? inscripcion
  ) {
    if (user == null || user.bosqueId == null || user.bosqueId.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
        child: const Text(
          'Debes pertenecer a un bosque para poder inscribirte a un evento.',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }

    Widget mainButton;
    Widget? secondaryButton;

    switch (estado) {
      case 'sin_inscribir':
        if (noPuedeInscribirse) {
          mainButton = const ElevatedButton(
            onPressed: null,
            child: Text('Inscripciones cerradas'),
          );
        } else {
          mainButton = ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => _navegarDocumentos(user, inscripcion),
            child: const Text('Inscribirme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          );
        }
        break;
      case 'borrador':
        mainButton = ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => _navegarDocumentos(user, inscripcion),
          child: const Text('Continuar inscripcion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        );
        break;
      case 'pendiente':
        mainButton = const ElevatedButton(
          onPressed: null,
          child: Text('En revision por coordinador', style: TextStyle(fontWeight: FontWeight.bold)),
        );
        break;
      case 'observada':
        mainButton = ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () => _navegarDocumentos(user, inscripcion),
          child: const Text('Corregir documentos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        );
        break;
      case 'aprobada':
        mainButton = ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () {}, // Puede llevar a ver el QR o ticket
          child: const Text('Inscripcion aprobada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        );
        break;
      case 'rechazada':
        mainButton = const ElevatedButton(
          onPressed: null,
          child: Text('Inscripcion rechazada'),
        );
        break;
      case 'cancelada':
        mainButton = const ElevatedButton(
          onPressed: null,
          child: Text('Inscripcion cancelada'),
        );
        break;
      default:
        mainButton = const SizedBox.shrink();
    }

    if (estado != 'sin_inscribir' && estado != 'rechazada' && estado != 'cancelada') {
      secondaryButton = TextButton(
        onPressed: () async {
           // TODO: implementar cancelar inscripción
        },
        child: const Text('Cancelar inscripcion', style: TextStyle(color: AppColors.error)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 50, child: mainButton),
        if (secondaryButton != null) ...[
          const SizedBox(height: 12),
          secondaryButton,
        ],
      ],
    );
  }

  void _navegarDocumentos(dynamic user, InscripcionModel? inscripcion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InscripcionDocumentosScreen(
          evento: widget.evento,
          inscripcion: inscripcion,
          user: user,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
