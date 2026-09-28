import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/bosque_model.dart';
import '../../../models/solicitud_model.dart';
import '../../../services/auth_provider.dart';
import '../../../services/bosque_service.dart';

class BosqueSolicitudScreen extends StatefulWidget {
  final BosqueModel? bosque;

  const BosqueSolicitudScreen({super.key, this.bosque});

  @override
  State<BosqueSolicitudScreen> createState() => _BosqueSolicitudScreenState();
}

class _BosqueSolicitudScreenState extends State<BosqueSolicitudScreen> {
  final BosqueService _bosqueService = BosqueService();
  BosqueModel? _selectedBosque;
  List<BosqueModel> _bosquesDisponibles = [];
  bool _isLoading = false;
  bool _isLoadingData = true;
  SolicitudModel? _solicitudActiva;

  @override
  void initState() {
    super.initState();
    _selectedBosque = widget.bosque;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    try {
      final bosques = await _bosqueService.obtenerBosques();
      final miSolicitud = await _bosqueService.obtenerMiSolicitud(user.id);

      if (mounted) {
        setState(() {
          _bosquesDisponibles = bosques;
          _solicitudActiva = miSolicitud;
          if (_selectedBosque == null && bosques.isNotEmpty) {
            _selectedBosque = bosques.first;
          }
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _submitSolicitud() async {
    if (_selectedBosque == null) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final solicitud = SolicitudModel(
        id: const Uuid().v4(),
        userId: user.id,
        userName: '${user.name} ${user.apellidos}'.trim(),
        bosqueId: _selectedBosque!.id,
        bosqueNombre: _selectedBosque!.nombre,
        status: SolicitudStatus.pendiente,
        createdAt: DateTime.now(),
      );

      await _bosqueService.crearSolicitud(solicitud);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada exitosamente')),
        );
        setState(() {
          _solicitudActiva = solicitud;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar solicitud: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelarSolicitud() async {
    if (_solicitudActiva == null) return;

    setState(() => _isLoading = true);

    try {
      await _bosqueService.cancelarSolicitud(_solicitudActiva!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud cancelada')),
        );
        setState(() {
          _solicitudActiva = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Solicitud de Ingreso'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _solicitudActiva != null
                  ? _buildEstadoSolicitudExistente()
                  : _buildFormularioSolicitud(),
            ),
    );
  }

  Widget _buildEstadoSolicitudExistente() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.hourglass_top_outlined, size: 54, color: AppColors.accentYellow),
          const SizedBox(height: 16),
          const Text(
            'Solicitud en curso',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Has solicitado unirte a ${_solicitudActiva!.bosqueNombre}. El coordinador del bosque revisara tu perfil.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _cancelarSolicitud,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Cancelar Solicitud', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioSolicitud() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Elige el bosque al que deseas unirte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Una vez enviada la solicitud, el coordinador correspondiente podra autorizar tu ingreso.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<BosqueModel>(
            value: _selectedBosque,
            decoration: const InputDecoration(
              labelText: 'Bosque disponible *',
              border: OutlineInputBorder(),
            ),
            items: _bosquesDisponibles.map((b) {
              return DropdownMenuItem(
                value: b,
                child: Text('${b.nombre} (${b.zona})'),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _selectedBosque = val);
            },
          ),
          if (_selectedBosque != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Descripcion: ${_selectedBosque!.descripcion.isNotEmpty ? _selectedBosque!.descripcion : "Sin descripcion"}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Miembros actuales: ${_selectedBosque!.miembros}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_isLoading || _selectedBosque == null) ? null : _submitSolicitud,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Enviar Solicitud de Ingreso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
