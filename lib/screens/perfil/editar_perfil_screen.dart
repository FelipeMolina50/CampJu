import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_provider.dart';
import '../../../models/user_model.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telefonoController = TextEditingController();
  final _epsController = TextEditingController();
  final _ocupacionController = TextEditingController();
  final _numeroResolucionController = TextEditingController();

  String? _selectedMunicipio;
  DateTime? _fechaIngresoPrograma;
  String? _selectedGenero;
  String? _selectedOrientacionSexual;
  String? _selectedDiscapacidad;
  String? _selectedGrupoPoblacional;
  bool? _esVictimaConflicto;
  String? _selectedZonaDondeVive;
  String? _selectedNivelEducativo;

  File? _selectedImage;
  bool _isLoading = false;

  final List<String> _municipiosCundinamarca = [
    'Agua de Dios', 'Albán', 'Anapoima', 'Anolaima', 'Apulo', 'Arbeláez',
    'Beltrán', 'Bituima', 'Bojacá', 'Cabrera', 'Cachipay', 'Cajicá',
    'Caparrapí', 'Cáqueza', 'Carmen de Carupa', 'Chaguaní', 'Chía',
    'Chipaque', 'Choachí', 'Chocontá', 'Cogua', 'Cota', 'Cucunubá',
    'El Colegio', 'El Peñón', 'El Rosal', 'Facatativá', 'Fómeque',
    'Fosca', 'Funza', 'Fúquene', 'Fusagasugá', 'Gachalá', 'Gachancipá',
    'Gachetá', 'Gama', 'Girardot', 'Granada', 'Guachetá', 'Guaduas',
    'Guasca', 'Guataquí', 'Guatavita', 'Guayabal de Síquima', 'Guayabetal',
    'Gutiérrez', 'Jerusalén', 'Junín', 'La Calera', 'La Mesa', 'La Palma',
    'La Peña', 'La Vega', 'Lenguazaque', 'Machetá', 'Madrid', 'Manta',
    'Medina', 'Mosquera', 'Nariño', 'Nemocón', 'Nilo', 'Nimaima',
    'Nocaima', 'Pacho', 'Paime', 'Pandi', 'Paratebueno', 'Pasca',
    'Puerto Salgar', 'Pulí', 'Quebradanegra', 'Quetame', 'Quipile',
    'Ricaurte', 'San Antonio del Tequendama', 'San Bernardo', 'San Cayetano',
    'San Francisco', 'San Juan de Rioseco', 'Sasaima', 'Sesquilé',
    'Sibaté', 'Silvania', 'Simijaca', 'Soacha', 'Sopó', 'Subachoque',
    'Suesca', 'Supatá', 'Susa', 'Sutatausa', 'Tabio', 'Tausa',
    'Tena', 'Tenjo', 'Tibirita', 'Tocaima', 'Tocancipá',
    'Topaipí', 'Ubalá', 'Ubaque', 'Ubaté', 'Une', 'Útica', 'Venecia',
    'Vergara', 'Vianí', 'Villagómez', 'Villapinzón', 'Villeta',
    'Viotá', 'Yacopí', 'Zipacón', 'Zipaquirá'
  ];

  final List<String> _generos = ['Masculino', 'Femenino', 'Otro', 'Prefiero no decir'];
  final List<String> _orientacionesSexuales = ['Heterosexual', 'Homosexual', 'Bisexual', 'Otro', 'Prefiero no decir'];
  final List<String> _discapacidades = ['Ninguna', 'Física', 'Visual', 'Auditiva', 'Intelectual', 'Otra'];
  final List<String> _gruposPoblacionales = ['Ninguno', 'Indígena', 'Afrodescendiente', 'ROM/Gitana', 'Otro'];
  final List<String> _zonas = ['Urbana', 'Rural'];
  final List<String> _nivelesEducativos = ['Ninguno', 'Primaria', 'Secundaria', 'Técnico', 'Universitario', 'Posgrado'];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _telefonoController.text = user.telefono;
      _epsController.text = user.eps;
      _selectedMunicipio = user.municipio;
      _fechaIngresoPrograma = user.fechaIngresoPrograma;
      _selectedGenero = user.genero;
      _selectedOrientacionSexual = user.orientacionSexual;
      _selectedDiscapacidad = user.discapacidad;
      _selectedGrupoPoblacional = user.grupoPoblacional;
      _esVictimaConflicto = user.esVictimaConflicto;
      _selectedZonaDondeVive = user.zonaDondeVive;
      _selectedNivelEducativo = user.nivelEducativo;
      _ocupacionController.text = user.ocupacion ?? '';
      _numeroResolucionController.text = user.numeroResolucion ?? '';
    }
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _epsController.dispose();
    _ocupacionController.dispose();
    _numeroResolucionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return null;

    try {
      final ref = FirebaseStorage.instance.ref().child('profile_images/$userId.jpg');
      await ref.putFile(_selectedImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir imagen: $e')),
      );
      return null;
    }
  }

  Future<void> _selectFechaIngreso(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaIngresoPrograma ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaIngresoPrograma) {
      setState(() {
        _fechaIngresoPrograma = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) throw Exception('Usuario no encontrado');

      String? photoUrl = user.photoUrl;
      if (_selectedImage != null) {
        photoUrl = await _uploadImage(user.id);
      }

      final updatedUser = UserModel(
        id: user.id,
        email: user.email,
        emailVerified: user.emailVerified,
        name: user.name,
        apellidos: user.apellidos,
        municipio: _selectedMunicipio ?? user.municipio,
        fechaNacimiento: user.fechaNacimiento,
        tipoDocumento: user.tipoDocumento,
        numeroDocumento: user.numeroDocumento,
        sexo: user.sexo,
        telefono: _telefonoController.text.trim(),
        eps: _epsController.text.trim(),
        fechaIngresoPrograma: _fechaIngresoPrograma,
        rango: user.rango,
        esArbolMayor: user.esArbolMayor,
        bosqueId: user.bosqueId,
        fechaIngresoBosque: user.fechaIngresoBosque,
        perfilCompleto: user.perfilCompleto,
        nombreAcudiente: user.nombreAcudiente,
        telefonoAcudiente: user.telefonoAcudiente,
        photoUrl: photoUrl,
        role: user.role,
        genero: _selectedGenero,
        orientacionSexual: _selectedOrientacionSexual,
        discapacidad: _selectedDiscapacidad,
        grupoPoblacional: _selectedGrupoPoblacional,
        esVictimaConflicto: _esVictimaConflicto,
        zonaDondeVive: _selectedZonaDondeVive,
        nivelEducativo: _selectedNivelEducativo,
        ocupacion: _ocupacionController.text.trim().isEmpty ? null : _ocupacionController.text.trim(),
        numeroResolucion: _numeroResolucionController.text.trim().isEmpty ? null : _numeroResolucionController.text.trim(),
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update(updatedUser.toJson());

      authProvider.setUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el perfil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Guardar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto de perfil
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (user.photoUrl != null ? NetworkImage(user.photoUrl!) : null),
                          backgroundColor: AppColors.primary,
                          child: (_selectedImage == null && user.photoUrl == null)
                              ? const Text('👤', style: TextStyle(fontSize: 48))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('Cambiar foto de perfil'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Información básica
              const Text(
                'Información Básica',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // EPS
              TextFormField(
                controller: _epsController,
                decoration: const InputDecoration(
                  labelText: 'EPS',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Municipio
              DropdownButtonFormField<String>(
                value: _selectedMunicipio,
                decoration: const InputDecoration(
                  labelText: 'Municipio',
                  border: OutlineInputBorder(),
                ),
                items: _municipiosCundinamarca.map((municipio) {
                  return DropdownMenuItem(
                    value: municipio,
                    child: Text(municipio),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedMunicipio = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fecha de ingreso al programa
              InkWell(
                onTap: () => _selectFechaIngreso(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de ingreso al programa',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _fechaIngresoPrograma != null
                        ? '${_fechaIngresoPrograma!.day}/${_fechaIngresoPrograma!.month}/${_fechaIngresoPrograma!.year}'
                        : 'Selecciona una fecha',
                    style: TextStyle(
                      color: _fechaIngresoPrograma != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Identidad
              const Text(
                'Identidad (Opcional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Género
              DropdownButtonFormField<String>(
                value: _selectedGenero,
                decoration: const InputDecoration(
                  labelText: 'Género',
                  border: OutlineInputBorder(),
                ),
                items: _generos.map((genero) {
                  return DropdownMenuItem(
                    value: genero,
                    child: Text(genero),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedGenero = value);
                },
              ),
              const SizedBox(height: 16),

              // Orientación sexual
              DropdownButtonFormField<String>(
                value: _selectedOrientacionSexual,
                decoration: const InputDecoration(
                  labelText: 'Orientación sexual',
                  border: OutlineInputBorder(),
                ),
                items: _orientacionesSexuales.map((orientacion) {
                  return DropdownMenuItem(
                    value: orientacion,
                    child: Text(orientacion),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedOrientacionSexual = value);
                },
              ),

              const SizedBox(height: 30),

              // Información social
              const Text(
                'Información Social (Opcional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Discapacidad
              DropdownButtonFormField<String>(
                value: _selectedDiscapacidad,
                decoration: const InputDecoration(
                  labelText: 'Discapacidad',
                  border: OutlineInputBorder(),
                ),
                items: _discapacidades.map((discapacidad) {
                  return DropdownMenuItem(
                    value: discapacidad,
                    child: Text(discapacidad),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedDiscapacidad = value);
                },
              ),
              const SizedBox(height: 16),

              // Grupo poblacional
              DropdownButtonFormField<String>(
                value: _selectedGrupoPoblacional,
                decoration: const InputDecoration(
                  labelText: 'Grupo poblacional',
                  border: OutlineInputBorder(),
                ),
                items: _gruposPoblacionales.map((grupo) {
                  return DropdownMenuItem(
                    value: grupo,
                    child: Text(grupo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedGrupoPoblacional = value);
                },
              ),
              const SizedBox(height: 16),

              // Víctima de conflicto armado
              SwitchListTile(
                title: const Text('¿Es víctima de conflicto armado?'),
                value: _esVictimaConflicto ?? false,
                onChanged: (value) {
                  setState(() => _esVictimaConflicto = value);
                },
              ),

              const SizedBox(height: 30),

              // Contexto
              const Text(
                'Contexto (Opcional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Zona donde vive
              DropdownButtonFormField<String>(
                value: _selectedZonaDondeVive,
                decoration: const InputDecoration(
                  labelText: 'Zona donde vive',
                  border: OutlineInputBorder(),
                ),
                items: _zonas.map((zona) {
                  return DropdownMenuItem(
                    value: zona,
                    child: Text(zona),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedZonaDondeVive = value);
                },
              ),
              const SizedBox(height: 16),

              // Nivel educativo
              DropdownButtonFormField<String>(
                value: _selectedNivelEducativo,
                decoration: const InputDecoration(
                  labelText: 'Nivel educativo',
                  border: OutlineInputBorder(),
                ),
                items: _nivelesEducativos.map((nivel) {
                  return DropdownMenuItem(
                    value: nivel,
                    child: Text(nivel),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedNivelEducativo = value);
                },
              ),
              const SizedBox(height: 16),

              // Ocupación
              TextFormField(
                controller: _ocupacionController,
                decoration: const InputDecoration(
                  labelText: 'Ocupación',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

