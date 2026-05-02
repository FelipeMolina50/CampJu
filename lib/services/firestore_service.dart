import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).add(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(docId)
          .set(data, SetOptions(merge: merge));
    } catch (e) {
      rethrow;
    }
  }

  Future<DocumentSnapshot> getDocument(
    String collection,
    String docId,
  ) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      rethrow;
    }
  }

  Future<QuerySnapshot> getCollectionDocuments(
    String collection, {
    Query Function(CollectionReference)? where,
  }) async {
    try {
      CollectionReference collectionRef = _firestore.collection(collection);
      if (where != null) {
        return await where(collectionRef).get();
      }
      return await collectionRef.get();
    } catch (e) {
      rethrow;
    }
  }

  Stream<QuerySnapshot> streamCollectionDocuments(
    String collection, {
    Query Function(CollectionReference)? where,
  }) {
    try {
      CollectionReference collectionRef = _firestore.collection(collection);
      if (where != null) {
        return where(collectionRef).snapshots();
      }
      return collectionRef.snapshots();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection(collection)
          .doc(docId)
          .update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDocument(
    String collection,
    String docId,
  ) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
