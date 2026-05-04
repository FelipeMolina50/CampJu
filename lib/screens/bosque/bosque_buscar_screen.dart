import 'package:flutter/material.dart';
import 'package:campju/core/constants/app_colors.dart';
import 'package:campju/core/constants/app_styles.dart';
import 'package:campju/core/widgets/custom_textfield.dart';
import 'package:campju/core/widgets/custom_button.dart';
import 'package:campju/models/bosque_model.dart';

class BosqueBuscarScreen extends StatefulWidget {
  const BosqueBuscarScreen({super.key});

  @override
  State<BosqueBuscarScreen> createState() => _BosqueBuscarScreenState();
}

class _BosqueBuscarScreenState extends State<BosqueBuscarScreen> {
  final _searchController = TextEditingController();
  List<BosqueModel> bosques = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBosques();
  }

  void _loadBosques() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      bosques = [
        BosqueModel(
          id: '1',
          nombre: 'Bosque Verde',
          descripcion: 'Bosque del norte',
          zona: 'Zona Norte',
          liderId: 'juan123',
          miembros: 25,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        BosqueModel(
          id: '2',
          nombre: 'Bosque Azul',
          descripcion: 'Bosque del sur',
          zona: 'Zona Sur',
          liderId: 'maria456',
          miembros: 18,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });
  }

  void _search() {
    // Search functionality will be implemented with real API
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Buscar Bosques',
          style: AppStyles.heading4.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              label: 'Buscar por nombre o zona',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
              onChanged: (value) => _search(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: bosques.length,
                    itemBuilder: (context, index) {
                      final bosque = bosques[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              '${bosque.miembros}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(bosque.nombre, style: AppStyles.heading4),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Zona: ${bosque.zona}'),
                              Text('Líder ID: ${bosque.liderId}'),
                            ],
                          ),
                          trailing: CustomButton(
                          label: 'Ver Detalle',
                          height: 40,
                           onPressed: () async {
                          // Navigate to bosque_detalle_screen
                          },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
