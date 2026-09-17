import '../models/bosque_model.dart';
import '../models/miembro_model.dart';
import '../models/solicitud_model.dart';
import 'firestore_service.dart';
import '../core/constants/app_constants.dart';

import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

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
      
      // Verificar 1 bosque máximo por coordinador
      dynamic existingBosques;
      try {
        existingBosques = await _firestoreService.getCollectionDocuments(
          _bosqueCollection,
          where: (ref) => ref.where('liderId', isEqualTo: coordinadorId),
        );
      } catch (e) {
        throw Exception('No tienes permisos para leer los bosques. Revisa las Reglas de Firestore. Detalles: $e');
      }
      if (existingBosques.docs.isNotEmpty) {
        throw Exception('Ese coordinador ya lidera un bosque. Un coordinador solo puede tener uno.');
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
        throw Exception('No tienes permisos para crear el bosque. Detalles: $e');
      }

      // 4. Actualizar rol del nuevo coordinador a rol 1 (Coordinador)
      try {
        final coordDoc = await _firestoreService.getDocument('users', coordinadorId);
        final coordData = coordDoc.data() as Map<String, dynamic>?;
        if (coordData != null) {
          final currentRole = coordData['role'] ?? 0;
          if (currentRole == 0) { // Si era campista, subirlo a coordinador
            await _firestoreService.updateDocument('users', coordinadorId, {'role': 1});
          }
        }
      } catch (e) {
        debugPrint('Error actualizando rol del coordinador: $e');
        // No bloqueamos la creación del bosque por esto, pero lo logueamos
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

  Future<void> eliminarBosque(String bosqueId, String email) async {
    try {
      if (email != AppConstants.superAdminEmail) {
        throw Exception('Correo no autorizado para eliminar bosques');
      }
      
      // 1. Borrar solicitudes
      final solicitudes = await _firestoreService.getCollectionDocuments(_solicitudCollection,
          where: (ref) => ref.where('bosqueId', isEqualTo: bosqueId));
      for (var doc in solicitudes.docs) {
        await _firestoreService.deleteDocument(_solicitudCollection, doc.id);
      }
      
      // 2. Borrar miembros y limpiar usuarios
      final miembros = await _firestoreService.getCollectionDocuments(_miembroCollection,
          where: (ref) => ref.where('bosqueId', isEqualTo: bosqueId));
      for (var doc in miembros.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['usuarioId'] as String?;
        if (userId != null) {
          try {
            await _firestoreService.updateDocument('users', userId, {
              'bosqueId': null,
              'fechaIngresoBosque': null,
            });
          } catch (e) {
            debugPrint('No se pudo limpiar bosqueId para usuario $userId');
          }
        }
        await _firestoreService.deleteDocument(_miembroCollection, doc.id);
      }
      
      // 3. Borrar el bosque
      await _firestoreService.deleteDocument(_bosqueCollection, bosqueId);
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
      // Simplificamos la consulta quitando el orderBy para evitar errores de índices faltantes
      final snapshot = await _firestoreService.getCollectionDocuments(
        _solicitudCollection,
        where: (ref) => ref
            .where('bosqueId', isEqualTo: bosqueId)
            .where('status', isEqualTo: 'pendiente'),
      );
      
      final solicitudes = snapshot.docs
          .map((doc) =>
              SolicitudModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
          
      // Ordenamos en memoria
      solicitudes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return solicitudes;
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

  Future<SolicitudModel?> obtenerMiSolicitud(String userId) async {
    try {
      final snapshot = await _firestoreService.getCollectionDocuments(
        _solicitudCollection,
        where: (ref) => ref
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'pendiente'),
      );
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return SolicitudModel.fromJson(
          {...doc.data() as Map<String, dynamic>, 'id': doc.id});
    } catch (e) {
      return null;
    }
  }

  Future<MiembroModel?> obtenerMiMembresia(String userId) async {
    try {
      final snapshot = await _firestoreService.getCollectionDocuments(
        _miembroCollection,
        where: (ref) => ref.where('usuarioId', isEqualTo: userId),
      );
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return MiembroModel.fromJson(
          {...doc.data() as Map<String, dynamic>, 'id': doc.id});
    } catch (e) {
      return null;
    }
  }

  Future<void> cancelarSolicitud(String solicitudId) async {
    try {
      await _firestoreService.deleteDocument(_solicitudCollection, solicitudId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> aceptarSolicitud(SolicitudModel solicitud) async {
    try {
      final uid = solicitud.userId;
      final bid = solicitud.bosqueId;

      // 1. Usamos el uid del usuario como ID del documento en 'miembros' para evitar duplicados exactos
      final miembro = MiembroModel(
        id: uid, // Importante: ID fijo por usuario
        bosqueId: bid,
        usuarioId: uid,
        nombre: solicitud.userName,
        rol: 'campista',
        fechaIngreso: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.setDocument(_miembroCollection, uid, miembro.toJson());
      
      // 2. Intentar borrar la solicitud lo antes posible
      await _firestoreService.deleteDocument(_solicitudCollection, solicitud.id);
      
      // 3. Vincular el bosqueId al usuario (Esto requiere las nuevas reglas que te pasé)
      await _firestoreService.updateDocument('users', uid, {
        'bosqueId': bid,
        'fechaIngresoBosque': DateTime.now().toIso8601String(),
      });

      // 4. Actualizar contador de miembros en el bosque
      final bosqueDoc = await _firestoreService.getDocument(_bosqueCollection, bid);
      if (bosqueDoc.exists) {
        // Obtenemos el conteo real de la colección para ser exactos
        final miembrosSnapshot = await _firestoreService.getCollectionDocuments(
          _miembroCollection,
          where: (ref) => ref.where('bosqueId', isEqualTo: bid),
        );
        await _firestoreService.updateDocument(_bosqueCollection, bid, {
          'miembros': miembrosSnapshot.docs.length,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
    } catch (e) {
      debugPrint('Error en aceptarSolicitud: $e');
      rethrow;
    }
  }

  Future<void> rechazarSolicitud(String solicitudId) async {
    try {
      await _firestoreService.deleteDocument(_solicitudCollection, solicitudId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelarMembresia(String miembroId) async {
    try {
      await _firestoreService.deleteDocument(_miembroCollection, miembroId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> abandonarBosque(String userId, String bosqueId) async {
    try {
      // 1. Buscar el documento de membresía
      final snapshot = await _firestoreService.getCollectionDocuments(
        _miembroCollection,
        where: (ref) => ref
            .where('usuarioId', isEqualTo: userId)
            .where('bosqueId', isEqualTo: bosqueId),
      );
      
      if (snapshot.docs.isNotEmpty) {
        await _firestoreService.deleteDocument(_miembroCollection, snapshot.docs.first.id);
      }
      
      // 2. Limpiar el perfil del usuario
      await _firestoreService.updateDocument('users', userId, {
        'bosqueId': null,
        'fechaIngresoBosque': null,
      });
      
      // 3. Actualizar el contador del bosque
      final bosqueDoc = await _firestoreService.getDocument(_bosqueCollection, bosqueId);
      if (bosqueDoc.exists) {
        final data = bosqueDoc.data() as Map<String, dynamic>;
        final currentCount = data['miembros'] ?? 0;
        await _firestoreService.updateDocument(_bosqueCollection, bosqueId, {
          'miembros': currentCount > 0 ? currentCount - 1 : 0,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }
}
