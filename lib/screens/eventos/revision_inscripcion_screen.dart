import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../models/evento_model.dart';
import '../../models/inscripcion_model.dart';
import '../../services/auth_provider.dart';
import '../../services/evento_service.dart';
import '../../services/supabase_storage_service.dart';

class RevisionInscripcionScreen extends StatefulWidget {
  final InscripcionModel inscripcion;
  final EventoModel evento;

  const RevisionInscripcionScreen({
    super.key,
    required this.inscripcion,
    required this.evento,
  });

  @override
  State<RevisionInscripcionScreen> createState() => _RevisionInscripcionScreenState();
}

class _RevisionInscripcionScreenState extends State<RevisionInscripcionScreen> {
  final EventoService _eventoService = EventoService();
  bool _isLoading = false;

  Future<void> _abrirDocumento(String path) async {
    setState(() => _isLoading = true);
    try {
      final url = await SupabaseStorageService.obtenerUrlFirmada(path);
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
        throw Exception('No se pudo abrir la URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir documento: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _marcarDocumento(String docId, String estado) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    String? nota;
    if (estado == 'rechazado') {
      final notaCtrl = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Observar documento'),
          content: TextField(
            controller: notaCtrl,
            decoration: const InputDecoration(labelText: 'Motivo del rechazo *'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Observar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true || notaCtrl.text.trim().isEmpty) return;
      nota = notaCtrl.text.trim();
    }

    setState(() => _isLoading = true);
    try {
      await _eventoService.revisarDocumento(
        inscripcionId: widget.inscripcion.id,
        docReqId: docId,
        estado: estado,
        nota: nota,
        revisorId: user.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _aprobarInscripcion() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _eventoService.aprobarInscripcion(
        inscripcionId: widget.inscripcion.id,
        eventoId: widget.evento.id,
        revisorId: user.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscripcion aprobada exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al aprobar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _devolverInscripcion() async {
    // Esto se usa cuando hay documentos observados
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      // Simplemente cambiamos el estado principal a observada
      await _eventoService.rechazarInscripcion(
        inscripcionId: widget.inscripcion.id,
        motivo: 'Documentos observados',
        revisorId: user.id, // Reusamos el metodo pero podríamos hacerlo diferente
      );
      // Actualizar el estado a observada en la BD (rechazarInscripcion la pasa a rechazada)
      // Necesitamos un metodo cambiarEstadoInscripcion en _eventoService, o lo hacemos aquí
      // Wait, _eventoService doesn't have cambiarEstadoInscripcion. Let's do it manually just updating it.
      await _eventoService.enviarInscripcion(InscripcionModel.fromMap(
        {...widget.inscripcion.toMap(), 'estado': 'observada', 'revisadoPor': user.id}, 
        widget.inscripcion.id
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devuelta al campista con observaciones.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final esAutoInscripcion = user?.id == widget.inscripcion.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Revisar Inscripcion'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<InscripcionModel?>(
        stream: _eventoService.streamMiInscripcion(widget.evento.id, widget.inscripcion.uid),
        builder: (context, snapshot) {
          final insc = snapshot.data ?? widget.inscripcion;
          
          bool todosObligatoriosOk = true;
          bool algunRechazado = false;

          for (var docReq in widget.evento.documentosRequeridos) {
            final doc = insc.documentos[docReq.id];
            if (doc != null && doc.estado == 'rechazado') {
              algunRechazado = true;
            }
            if (docReq.obligatorio && (doc == null || doc.estado != 'ok')) {
              todosObligatoriosOk = false;
            }
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCampista(insc),
                    const SizedBox(height: 24),
                    const Text(
                      'Documentos adjuntos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    ...widget.evento.documentosRequeridos.map((req) {
                      final doc = insc.documentos[req.id];
                      return _buildDocRevisorRow(req, doc);
                    }).toList(),
                    const SizedBox(height: 40),
                    
                    if (esAutoInscripcion)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Text(
                          'No puedes aprobar tu propia inscripcion; la revisara el Super Admin.',
                          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (insc.estado != 'aprobada' && insc.estado != 'rechazada') ...[
                      if (algunRechazado)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            onPressed: _isLoading ? null : _devolverInscripcion,
                            child: const Text('Devolver con observaciones', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: todosObligatoriosOk ? Colors.green : Colors.grey),
                            onPressed: (todosObligatoriosOk && !_isLoading) ? _aprobarInscripcion : null,
                            child: const Text('Aprobar Inscripcion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black45,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCampista(InscripcionModel insc) {
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
          Text(insc.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Documento: ${insc.documentoId}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text('Municipio: ${insc.municipio}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text('Sexo: ${insc.sexo}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text('Telefono: ${insc.telefono}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          if (insc.autorizacionDatosAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                const Expanded(child: Text('Autorizo el tratamiento de datos', style: TextStyle(color: Colors.green, fontSize: 12))),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDocRevisorRow(DocumentoRequerido req, DocumentoInscripcion? doc) {
    if (doc == null || doc.path.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text('${req.nombre} - Faltante', style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: doc.estado == 'ok' ? Colors.green : (doc.estado == 'rechazado' ? AppColors.error : AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(req.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              IconButton(
                icon: const Icon(Icons.open_in_new, color: AppColors.primary),
                tooltip: 'Ver documento',
                onPressed: () => _abrirDocumento(doc.path),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Observar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                onPressed: doc.estado == 'rechazado' ? null : () => _marcarDocumento(req.id, 'rechazado'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Aprobar doc'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: doc.estado == 'ok' ? null : () => _marcarDocumento(req.id, 'ok'),
              ),
            ],
          ),
          if (doc.estado == 'rechazado' && doc.nota != null) ...[
            const SizedBox(height: 8),
            Text('Nota: ${doc.nota}', style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ]
        ],
      ),
    );
  }
}
