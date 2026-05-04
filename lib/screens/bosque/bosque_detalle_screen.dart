import 'package:flutter/material.dart';
import 'package:campju/core/constants/app_styles.dart';
import 'package:campju/models/bosque_model.dart';

class BosqueDetalleScreen extends StatelessWidget {
  final String id;
  const BosqueDetalleScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    // Mock bosque data
    final bosque = BosqueModel(
      id: id,
      nombre: 'Bosque Ejemplo $id',
      descripcion: 'Descripción del bosque.',
      zona: 'Zona Norte',
      liderId: 'lider123',
      fotoUrl: '',
      miembros: 42,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(title: Text(bosque.nombre)),
      body: Padding(
        padding: AppStyles.padding16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(bosque.descripcion, style: AppStyles.bodyLarge),
            Text('Zona: ${bosque.zona}'),
            Text('Líder ID: ${bosque.liderId}'),
            Text('Miembros: ${bosque.miembros}'),
          ],
        ),
      ),
    );
  }
}

