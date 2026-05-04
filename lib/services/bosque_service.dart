import '../models/bosque_model.dart';
import '../models/miembro_model.dart';
import '../models/solicitud_model.dart';
import 'firestore_service.dart';
import '../core/constants/app_constants.dart';

import 'package:uuid/uuid.dart';

class BosqueService {
  final FirestoreService _firestoreService = FirestoreService();
  final String _bosqueCollection = 'bosques';
  final String _miembroCollection = 'miembros';
  final String _solicitudCollection = 'solicitudes';

  Future<List<BosqueModel>> obtenerBosques() async {
    try {
      final snapshot =
          await _firestoreService.getCollectionDocuments(_bosqueCollection);
      return snapshot.docs
          .map((doc) =>
              BosqueModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<BosqueModel?> obtenerBosque(String bosqueId) async {
    try {
      final doc =
          await _firestoreService.getDocument(_bosqueCollection, bosqueId);
      if (!doc.exists) return null;
      return BosqueModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> crearBosque(BosqueModel bosque, String userId, String coordinadorId, String coordinadorNombre) async {
    try {
      // Validar admin
      final userDoc = await _firestoreService.getDocument('users', userId);
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      bool isSuperAdmin = userData != null && userData['email'] == AppConstants.superAdminEmail;
      bool isAdminRole = userData != null && (userData['role'] ?? 0) == 2;
      
      if (!isSuperAdmin && !isAdminRole) {
        throw Exception('Solo administradores pueden crear bosques');
      }
      
      // Auto-update role in DB if it's the super admin but role is wrong
      if (isSuperAdmin && !isAdminRole) {
        try {
          await _firestoreService.updateDocument('users', userId, {'role': 2});
        } catch (e) {
          throw Exception('No tienes permisos en Firestore para actualizar tu rol. Revisa las Reglas de Firestore (Console). Detalles: $e');
        }
      }
      
      // Verificar 1 bosque máximo por admin
      final QuerySnapshot existingBosques;
      try {
        existingBosques = await _firestoreService.getCollectionDocuments(
          _bosqueCollection,
          where: (ref) => ref.where('liderId', isEqualTo: userId),
        );
      } catch (e) {
        throw Exception('No tienes permisos para leer los bosques. Revisa las Reglas de Firestore. Detalles: $e');
      }
      if (existingBosques.docs.isNotEmpty) {
        throw Exception('Ya tienes un bosque. Un admin solo puede tener uno.');
      }
      
      // Crear con liderId desde constructor
      final bosqueConLider = BosqueModel(
        id: bosque.id,
        nombre: bosque.nombre,
        descripcion: bosque.descripcion,
        zona: bosque.zona,
        liderId: coordinadorId,
        fotoUrl: bosque.fotoUrl,
        miembros: 1, // Empieza con 1 miembro
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Crear bosque
      try {
        await _firestoreService.setDocument(_bosqueCollection, bosque.id, bosqueConLider.toFirestore());
      } catch (e) {
        throw Exception('No tienes permisos para crear el bosque. Revisa las reglas de la colección "bosques" en Firebase. Detalles: $e');
      }
      
      final miembro = MiembroModel(
        id: Uuid().v4(),
        bosqueId: bosque.id,
        usuarioId: coordinadorId,
        nombre: coordinadorNombre,
        rol: 'coordinador',
        fechaIngreso: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      try {
        await _firestoreService.setDocument(_miembroCollection, miembro.id, miembro.toJson());
      } catch (e) {
        throw Exception('Bosque creado, pero falló al añadirte como miembro por permisos. Detalles: $e');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> crearSolicitud(SolicitudModel solicitud) async {
    try {
      await _firestoreService.setDocument(
        _solicitudCollection,
        solicitud.id,
        solicitud.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SolicitudModel>> obtenerSolicitudes(String bosqueId) async {
    try {
      final snapshot = await _firestoreService.getCollectionDocuments(
        _solicitudCollection,
        where: (ref) =>
            ref.where('bosqueId', isEqualTo: bosqueId)
                .orderBy('createdAt', descending: true),
      );
      return snapshot.docs
          .map((doc) =>
              SolicitudModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<MiembroModel>> obtenerMiembros(String bosqueId) async {
    try {
      final snapshot = await _firestoreService.getCollectionDocuments(
        _miembroCollection,
        where: (ref) => ref.where('bosqueId', isEqualTo: bosqueId),
      );
      return snapshot.docs
          .map((doc) =>
              MiembroModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> agregarMiembro(MiembroModel miembro) async {
    try {
      await _firestoreService.setDocument(
        _miembroCollection,
        miembro.id,
        miembro.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }
}
