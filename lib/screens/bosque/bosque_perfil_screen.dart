  import 'package:flutter/material.dart';

class BosquePerfilScreen extends StatefulWidget {
  const BosquePerfilScreen({super.key});

  @override
  State<BosquePerfilScreen> createState() => _BosquePerfilScreenState();
}

class _BosquePerfilScreenState extends State<BosquePerfilScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Bosque'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 50),
              const Text('BosquePerfilScreen'),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
