import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class BosqueSolicitudScreen extends StatefulWidget {
  const BosqueSolicitudScreen({super.key});

  @override
  State<BosqueSolicitudScreen> createState() => _BosqueSolicitudScreenState();
}

class _BosqueSolicitudScreenState extends State<BosqueSolicitudScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  final _mensajeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitSolicitud() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2)); // Mock service
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada exitosamente')),
        );
        _motivoController.clear();
        _mensajeController.clear();
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud de Ingreso')),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: AppStyles.padding16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text('Solicita ingresar al bosque', style: AppStyles.headlineSmall),
                const SizedBox(height: 30),

                // Motivo field
                Text('Motivo *', style: AppStyles.textSm.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _motivoController,
                  maxLines: 4,
                  validator: (value) => value!.isEmpty ? 'Motivo requerido' : null,
                  decoration: InputDecoration(
                    hintText: 'Describe tu motivo para unirte al bosque...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radiusMd),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radiusMd),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radiusMd),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: AppStyles.padding16,
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radiusMd),
                      borderSide: BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Mensaje field
                Text('Mensaje adicional', style: AppStyles.textSm.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _mensajeController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Mensaje opcional...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radiusMd),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radiusMd),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radiusMd),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: AppStyles.padding16,
                  ),
                ),
                const SizedBox(height: 30),

                // Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitSolicitud,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppStyles.radiusMd),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : Text('Enviar Solicitud', style: AppStyles.buttonText.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

