import 'package:flutter/material.dart';
import '../../../core/constants/app_styles.dart';

class CursoDetalleScreen extends StatelessWidget {
  final String id;
  const CursoDetalleScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Curso $id')),
      body: Padding(
        padding: AppStyles.padding16,
        child: Column(
          children: [
            Text('Detalle del curso $id', style: AppStyles.headlineSmall),
            const Text('Placeholder - pendiente implementación.'),
          ],
        ),
      ),
    );
  }
}

