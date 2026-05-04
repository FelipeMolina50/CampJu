import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bosque_model.dart';
import '../models/miembro_model.dart';
import '../models/solicitud_model.dart';
import 'firestore_service.dart';

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

  Future<void> crearBosque(BosqueModel bosque, String userId) async {
    try {
      // Validar admin
      final userDoc = await _firestoreService.getDocument('users', userId);
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null || (userData['role'] ?? 0) != 2) {
        throw Exception('Solo administradores pueden crear bosques');
      }
      
      // Verificar 1 bosque máximo por admin
      final existingBosques = await _firestoreService.getCollectionDocuments(
        _bosqueCollection,
        where: (ref) => ref.where('liderId', isEqualTo: userId),
      );
      if (existingBosques.docs.isNotEmpty) {
        throw Exception('Ya tienes un bosque. Un admin solo puede tener uno.');
      }
      
      // Crear con liderId desde constructor
      final bosqueConLider = BosqueModel(
        id: bosque.id,
        nombre: bosque.nombre,
        descripcion: bosque.descripcion,
        zona: bosque.zona,
        liderId: userId,
        fotoUrl: bosque.fotoUrl,
        miembros: 1, // Empieza con 1 miembro
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.setDocument(
        _bosqueCollection,
        bosque.id,
        bosqueConLider.toJson(),
      );
      
      // Auto-agregar como primer miembro/coordinador
      final miembro = MiembroModel(
        id: '${userId}_${bosque.id}',
        bosqueId: bosque.id,
        usuarioId: userId,
        nombre: userData['name'] ?? 'Admin',
        rol: 'coordinador',
        fechaIngreso: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestoreService.setDocument(
        _miembroCollection,
        miembro.id,
        miembro.toJson(),
      );
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
