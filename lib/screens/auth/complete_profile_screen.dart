import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/custom_button.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _numeroDocumentoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _epsController = TextEditingController();
  final _nombreAcudienteController = TextEditingController();
  final _telefonoAcudienteController = TextEditingController();

  String? _selectedMunicipio;
  DateTime? _fechaNacimiento;
  String? _selectedTipoDocumento;
  String? _selectedSexo;
  DateTime? _fechaIngresoPrograma;
  String? _selectedRango;

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

  final List<String> _tiposDocumento = ['TI', 'CC', 'CE', 'Pasaporte'];
  final List<String> _sexos = ['Masculino', 'Femenino', 'Intersexual'];
  final List<String> _rangos = ['Aspirante', 'Semilla', 'Raíz', 'Tallo', 'Hoja', 'Flor', 'Fruto'];

  @override
  void dispose() {
    _nameController.dispose();
    _apellidosController.dispose();
    _numeroDocumentoController.dispose();
    _telefonoController.dispose();
    _epsController.dispose();
    _nombreAcudienteController.dispose();
    _telefonoAcudienteController.dispose();
    super.dispose();
  }

  bool get _esMenorDeEdad {
    if (_fechaNacimiento == null) return false;
    final edad = DateTime.now().difference(_fechaNacimiento!).inDays ~/ 365;
    return edad < 18;
  }

  Future<void> _selectFechaNacimiento(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
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
    if (picked != null && picked != _fechaNacimiento) {
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }

  Future<void> _selectFechaIngreso(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
    debugPrint('=== INICIO GUARDADO PERFIL ===');

    if (!_formKey.currentState!.validate()) {
      debugPrint('Validación formulario falló');
      return;
    }

    if (_selectedMunicipio == null ||
        _fechaNacimiento == null ||
        _selectedTipoDocumento == null ||
        _selectedSexo == null ||
        _selectedRango == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor completa todos los campos obligatorios')),
        );
      }
      debugPrint('Campos obligatorios faltantes');
      return;
    }

    if (_esMenorDeEdad && (_nombreAcudienteController.text.isEmpty || _telefonoAcudienteController.text.isEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Como eres menor de edad, debes completar los datos del acudiente')),
        );
      }
      debugPrint('Datos acudiente faltantes para menor');
      return;
    }

    // Mostrar loading dialog
    late bool dialogClosed = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text('Completando tu perfil...', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => dialogClosed = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      debugPrint('Usuario encontrado: ${user?.id}');

      if (user == null) throw Exception('Usuario no encontrado');

      final updatedUser = UserModel(
        id: user.id,
        email: user.email,
        emailVerified: user.emailVerified,
        name: _nameController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        municipio: _selectedMunicipio!,
        fechaNacimiento: _fechaNacimiento!,
        tipoDocumento: _selectedTipoDocumento!,
        numeroDocumento: _numeroDocumentoController.text.trim(),
        sexo: _selectedSexo!,
        telefono: _telefonoController.text.trim(),
        eps: _epsController.text.trim(),
        fechaIngresoPrograma: _fechaIngresoPrograma,
        rango: _selectedRango!.toLowerCase(),
        esArbolMayor: user.esArbolMayor,
        bosqueId: user.bosqueId,
        fechaIngresoBosque: user.fechaIngresoBosque,
        perfilCompleto: true,
        nombreAcudiente: _esMenorDeEdad ? _nombreAcudienteController.text.trim() : null,
        telefonoAcudiente: _esMenorDeEdad ? _telefonoAcudienteController.text.trim() : null,
        photoUrl: user.photoUrl,
        role: user.role,
        genero: user.genero,
        orientacionSexual: user.orientacionSexual,
        discapacidad: user.discapacidad,
        grupoPoblacional: user.grupoPoblacional,
        esVictimaConflicto: user.esVictimaConflicto,
        zonaDondeVive: user.zonaDondeVive,
        nivelEducativo: user.nivelEducativo,
        ocupacion: user.ocupacion,
        numeroResolucion: user.numeroResolucion,
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
      );

      debugPrint('Datos user preparados, guardando en Firestore...');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .set(updatedUser.toJson(), SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              throw Exception('Timeout al guardar perfil (45s). Verifica conexión.');
            },
          );

      debugPrint('Perfil guardado en Firestore exitosamente');

      // Force refresh desde Firestore
      final refreshedDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .get();
      final refreshedUser = UserModel.fromJson(refreshedDoc.data()!);
      debugPrint('Perfil refrescado - perfilCompleto: ${refreshedUser.perfilCompleto}');

      if (!refreshedUser.perfilCompleto) {
        throw Exception('Firestore no actualizó perfilCompleto a true');
      }

      authProvider.setUser(refreshedUser);

      // Esperar cierre dialog
      await Future.delayed(const Duration(milliseconds: 500));
      if (!dialogClosed && context.mounted) {
        Navigator.of(context).pop();
      }

      debugPrint('Navegando directamente a PERFIL...');

      await Future.delayed(const Duration(milliseconds: 1200));

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('ERROR AL GUARDAR PERFIL: $e');
      if (context.mounted && !dialogClosed) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _saveProfile,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Completa tu Perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Para continuar, necesitamos completar tu información personal',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Nombre
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre(s) *',
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

                // Apellidos
                TextFormField(
                  controller: _apellidosController,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos *',
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
                  initialValue: _selectedMunicipio,
                  decoration: const InputDecoration(
                    labelText: 'Municipio *',
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

                // Fecha de nacimiento
                InkWell(
                  onTap: () => _selectFechaNacimiento(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de nacimiento *',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _fechaNacimiento != null
                          ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
                          : 'Selecciona una fecha',
                      style: TextStyle(
                        color: _fechaNacimiento != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tipo de documento
                DropdownButtonFormField<String>(
                  initialValue: _selectedTipoDocumento,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de documento *',
                    border: OutlineInputBorder(),
                  ),
                  items: _tiposDocumento.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedTipoDocumento = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Número de documento
                TextFormField(
                  controller: _numeroDocumentoController,
                  decoration: const InputDecoration(
                    labelText: 'Número de documento *',
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

                // Sexo
                DropdownButtonFormField<String>(
                  initialValue: _selectedSexo,
                  decoration: const InputDecoration(
                    labelText: 'Sexo de nacimiento *',
                    border: OutlineInputBorder(),
                  ),
                  items: _sexos.map((sexo) {
                    return DropdownMenuItem(
                      value: sexo,
                      child: Text(sexo),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSexo = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Teléfono
                TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
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
                    labelText: 'EPS *',
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

                // Fecha de ingreso al programa
                InkWell(
                  onTap: () => _selectFechaIngreso(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de ingreso al programa (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _fechaIngresoPrograma != null
                          ? '${_fechaIngresoPrograma!.day}/${_fechaIngresoPrograma!.month}/${_fechaIngresoPrograma!.year}'
                          : 'Selecciona una fecha (deja vacío si eres nuevo)',
                      style: TextStyle(
                        color: _fechaIngresoPrograma != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nivel/Rango en el programa
                DropdownButtonFormField<String>(
                  initialValue: _selectedRango,
                  decoration: const InputDecoration(
                    labelText: 'Nivel en el programa *',
                    border: OutlineInputBorder(),
                    helperText: 'Aspirante si eres nuevo, o tu rango actual si ya estás en el programa',
                  ),
                  items: _rangos.map((rango) {
                    return DropdownMenuItem(
                      value: rango,
                      child: Text(rango),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedRango = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Campos para menores de edad
                if (_esMenorDeEdad) ...[
                  const Text(
                    'Como eres menor de edad, necesitamos los datos de tu acudiente:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nombre del acudiente
                  TextFormField(
                    controller: _nombreAcudienteController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo del acudiente *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es obligatorio para menores de edad';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Teléfono del acudiente
                  TextFormField(
                    controller: _telefonoAcudienteController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono del acudiente *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es obligatorio para menores de edad';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                ],

                CustomButton(
                  label: 'Completar Perfil',
                  onPressed: _saveProfile,
                  height: 54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}