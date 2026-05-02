import 'package:flutter/material.dart';

class CursosScreen extends StatefulWidget {
  const CursosScreen({Key? key}) : super(key: key);

  @override
  State<CursosScreen> createState() => _CursosScreenState();
}

class _CursosScreenState extends State<CursosScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursos'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 50),
              const Text('CursosScreen'),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
