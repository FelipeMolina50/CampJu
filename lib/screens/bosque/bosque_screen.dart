import 'package:flutter/material.dart';

class BosqueScreen extends StatefulWidget {
  const BosqueScreen({Key? key}) : super(key: key);

  @override
  State<BosqueScreen> createState() => _BosqueScreenState();
}

class _BosqueScreenState extends State<BosqueScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Bosque'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 50),
              const Text('BosqueScreen'),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
