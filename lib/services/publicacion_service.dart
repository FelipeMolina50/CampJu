import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/publicacion_model.dart';
import '../models/comentario_model.dart';

class PublicacionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> crearPublicacion(PublicacionModel post) async {
    await _firestore.collection('publicaciones').add(post.toMap());
  }

  Future<List<PublicacionModel>> obtenerTodasLasPublicaciones({DocumentSnapshot? lastDocument, int limit = 10}) async {
    Query query = _firestore
        .collection('publicaciones')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => PublicacionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<bool> toggleLike(String publicacionId, String usuarioId) async {
    final likeRef = _firestore.collection('publicaciones').doc(publicacionId).collection('likes').doc(usuarioId);
    final postRef = _firestore.collection('publicaciones').doc(publicacionId);

    return await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      final postDoc = await transaction.get(postRef);

      if (!postDoc.exists) return false;

      int currentLikes = (postDoc.data()?['likesCount'] as int?) ?? 0;

      if (likeDoc.exists) {
        transaction.delete(likeRef);
        transaction.update(postRef, {'likesCount': currentLikes - 1});
        return false;
      } else {
        transaction.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        transaction.update(postRef, {'likesCount': currentLikes + 1});
        return true;
      }
    });
  }

  Future<bool> haDadoLike(String publicacionId, String usuarioId) async {
    final doc = await _firestore.collection('publicaciones').doc(publicacionId).collection('likes').doc(usuarioId).get();
    return doc.exists;
  }

  Stream<DocumentSnapshot> streamPublicacion(String publicacionId) {
    return _firestore.collection('publicaciones').doc(publicacionId).snapshots();
  }

  Stream<bool> streamUserLike(String publicacionId, String usuarioId) {
    return _firestore
        .collection('publicaciones')
        .doc(publicacionId)
        .collection('likes')
        .doc(usuarioId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> agregarComentario(ComentarioModel comentario) async {
    final postRef = _firestore.collection('publicaciones').doc(comentario.publicacionId);
    final commentRef = postRef.collection('comentarios').doc();

    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) throw Exception('Publicación no encontrada');

      int currentComments = (postDoc.data()?['commentsCount'] as int?) ?? 0;

      transaction.set(commentRef, comentario.toMap());
      transaction.update(postRef, {'commentsCount': currentComments + 1});
    });
  }

  Stream<List<ComentarioModel>> getComentariosStream(String publicacionId) {
    return _firestore
        .collection('publicaciones')
        .doc(publicacionId)
        .collection('comentarios')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComentarioModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> eliminarComentario(String publicacionId, String comentarioId) async {
    final postRef = _firestore.collection('publicaciones').doc(publicacionId);
    final commentRef = postRef.collection('comentarios').doc(comentarioId);

    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) return;

      int currentComments = (postDoc.data()?['commentsCount'] as int?) ?? 1;
      transaction.delete(commentRef);
      transaction.update(postRef, {'commentsCount': currentComments > 0 ? currentComments - 1 : 0});
    });
  }

  Future<void> eliminarPublicacion(String publicacionId) async {
    await _firestore.collection('publicaciones').doc(publicacionId).delete();
  }
}

