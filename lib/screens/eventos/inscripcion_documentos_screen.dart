import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../models/evento_model.dart';
import '../../models/inscripcion_model.dart';
import '../../services/evento_service.dart';
import '../../services/supabase_storage_service.dart';

class InscripcionDocumentosScreen extends StatefulWidget {
  final EventoModel evento;
  final InscripcionModel? inscripcion;
  final dynamic user;

  const InscripcionDocumentosScreen({
    super.key,
    required this.evento,
    required this.inscripcion,
    required this.user,
  });

  @override
  State<InscripcionDocumentosScreen> createState() => _InscripcionDocumentosScreenState();
}

class _InscripcionDocumentosScreenState extends State<InscripcionDocumentosScreen> {
  final EventoService _eventoService = EventoService();
  
  late InscripcionModel _inscripcionActual;
  bool _isLoading = false;
  bool _aceptaTratamientoDatos = false;
  Map<String, File> _archivosSeleccionados = {};

  @override
  void initState() {
    super.initState();
    if (widget.inscripcion != null) {
      _inscripcionActual = widget.inscripcion!;
      _aceptaTratamientoDatos = _inscripcionActual.autorizacionDatosAt != null;
    } else {
      _inscripcionActual = InscripcionModel(
        id: '${widget.evento.id}_${widget.user.id}',
        eventoId: widget.evento.id,
        uid: widget.user.id,
        bosqueId: widget.user.bosqueId ?? '',
        nombre: '${widget.user.name} ${widget.user.apellidos}'.trim(),
        documentoId: widget.user.numeroDocumento ?? '',
        municipio: widget.user.municipio ?? '',
        sexo: widget.user.sexo ?? '',
        telefono: widget.user.telefono ?? '',
        estado: 'borrador',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> _seleccionarArchivo(String docReqId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final sizeMb = file.lengthSync() / (1024 * 1024);
      if (sizeMb > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El archivo supera el limite de 5 MB.'), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      setState(() {
        _archivosSeleccionados[docReqId] = file;
      });
    }
  }

  Future<void> _enviarInscripcion() async {
    if (!_aceptaTratamientoDatos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar la política de tratamiento de datos.'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Validar requeridos
    bool faltaObligatorio = false;
    for (var doc in widget.evento.documentosRequeridos) {
      if (doc.obligatorio) {
        final docActual = _inscripcionActual.documentos[doc.id];
        final tieneSubido = docActual != null && (docActual.estado == 'ok' || docActual.estado == 'pendiente');
        final tieneSeleccionado = _archivosSeleccionados.containsKey(doc.id);
        
        if (!tieneSubido && !tieneSeleccionado) {
          faltaObligatorio = true;
          break;
        }
      }
    }

    if (faltaObligatorio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faltan documentos obligatorios.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final docsNuevos = Map<String, DocumentoInscripcion>.from(_inscripcionActual.documentos);

      for (var entry in _archivosSeleccionados.entries) {
        final docId = entry.key;
        final file = entry.value;
        final ext = file.path.split('.').last.toLowerCase();

        final path = await SupabaseStorageService.subirDocumentoInscripcion(
          file: file,
          eventoId: widget.evento.id,
          uid: widget.user.id,
          docId: docId,
          extension: ext,
        );

        docsNuevos[docId] = DocumentoInscripcion(path: path, estado: 'pendiente');
      }

      final inscripcionActualizada = InscripcionModel(
        id: _inscripcionActual.id,
        eventoId: _inscripcionActual.eventoId,
        uid: _inscripcionActual.uid,
        bosqueId: _inscripcionActual.bosqueId,
        nombre: _inscripcionActual.nombre,
        documentoId: _inscripcionActual.documentoId,
        municipio: _inscripcionActual.municipio,
        sexo: _inscripcionActual.sexo,
        nivel: _inscripcionActual.nivel,
        telefono: _inscripcionActual.telefono,
        estado: 'pendiente',
        documentos: docsNuevos,
        motivo: null, // se limpia motivo de rechazo si lo habia
        revisadoPor: _inscripcionActual.revisadoPor,
        revisadoAt: _inscripcionActual.revisadoAt,
        autorizacionDatosAt: _inscripcionActual.autorizacionDatosAt ?? DateTime.now(),
        createdAt: _inscripcionActual.createdAt,
        updatedAt: DateTime.now(),
      );

      await _eventoService.enviarInscripcion(inscripcionActualizada);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscripcion enviada para revision.')),
        );
        Navigator.pop(context); // Volver
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subir Documentos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Completa tu inscripcion',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sube los documentos requeridos. Los archivos deben ser PDF o Imagenes menores a 5 MB.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                
                ...widget.evento.documentosRequeridos.map((req) {
                  final docEstado = _inscripcionActual.documentos[req.id];
                  final fileSelec = _archivosSeleccionados[req.id];
                  return _buildDocRow(req, docEstado, fileSelec);
                }).toList(),

                const SizedBox(height: 30),
                CheckboxListTile(
                  title: const Text('Autorizo el tratamiento de mis datos personales y los de menores a mi cargo según la Política de Privacidad de CampJu.', style: TextStyle(fontSize: 13)),
                  value: _aceptaTratamientoDatos,
                  activeColor: AppColors.primary,
                  onChanged: _inscripcionActual.autorizacionDatosAt != null
                      ? null // Ya autorizó antes
                      : (val) {
                          setState(() => _aceptaTratamientoDatos = val ?? false);
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: _isLoading ? null : _enviarInscripcion,
                    child: const Text('Enviar Inscripcion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildDocRow(DocumentoRequerido req, DocumentoInscripcion? doc, File? selec) {
    Color estadoColor = AppColors.textSecondary;
    IconData estadoIcon = Icons.help_outline;
    String estadoTexto = 'Falta subir';
    
    if (doc != null) {
      if (doc.estado == 'ok') {
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        estadoTexto = 'Correcto';
      } else if (doc.estado == 'pendiente') {
        estadoColor = AppColors.accent;
        estadoIcon = Icons.schedule;
        estadoTexto = 'Pendiente de revision';
      } else if (doc.estado == 'rechazado') {
        estadoColor = AppColors.error;
        estadoIcon = Icons.cancel;
        estadoTexto = 'Rechazado';
      }
    }

    if (selec != null) {
      estadoColor = Colors.blue;
      estadoIcon = Icons.upload_file;
      estadoTexto = 'Listo para enviar';
    }

    final canUpload = doc == null || doc.estado == 'rechazado' || selec != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Expanded(
                child: Text(
                  '${req.nombre}${req.obligatorio ? " *" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
              ),
              if (canUpload)
                IconButton(
                  icon: const Icon(Icons.file_upload, color: AppColors.primary),
                  tooltip: 'Subir archivo',
                  onPressed: () => _seleccionarArchivo(req.id),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(estadoIcon, color: estadoColor, size: 16),
              const SizedBox(width: 6),
              Text(estadoTexto, style: TextStyle(color: estadoColor, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          if (doc?.estado == 'rechazado' && doc?.nota != null && selec == null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
              child: Text(
                'Nota: ${doc!.nota}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
          if (selec != null) ...[
            const SizedBox(height: 8),
            Text(
              'Archivo seleccionado: ${selec.path.split('/').last}',
              style: const TextStyle(fontSize: 12, color: Colors.blue, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
