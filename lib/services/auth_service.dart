import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService() {
    _firebaseAuth.setLanguageCode('es');
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return {
        'success': true,
        'user': _userFromFirebaseUser(userCredential.user)
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _mapAuthError(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Error inesperado: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> googleLogin(AuthCredential credential) async {
    try {
      final userCredential = await _firebaseAuth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 20));

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        _saveUserToFirestore(userCredential.user).catchError((error) {
          debugPrint(
              'Error guardando usuario en Firestore después del login: $error');
        });
      }

      return {
        'success': true,
        'user': _userFromFirebaseUser(userCredential.user),
        'isNewUser': userCredential.additionalUserInfo?.isNewUser == true,
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Tiempo de espera agotado al iniciar con Google.'
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _mapAuthError(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Error inesperado: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String name) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);
      _saveUserToFirestore(userCredential.user, name: name).catchError((error) {
        debugPrint(
            'Error guardando usuario en Firestore después del registro: $error');
      });

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      return {
        'success': true,
        'user': _userFromFirebaseUser(userCredential.user)
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _mapAuthError(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Error inesperado: ${e.toString()}'};
    }
  }

  String mapAuthError(String code) {
    return _mapAuthError(code);
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 8 caracteres.';
      case 'email-already-in-use':
        return 'El email ya está registrado. Inicia sesión o usa otro.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'user-not-found':
        return 'Este correo no está registrado.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'user-disabled':
        return 'Cuenta deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'no-password-provider':
        return 'Esta cuenta no admite recuperación de contraseña por email. Usa el método de inicio de sesión correspondiente.';
      default:
        return 'Error de autenticación: $code';
    }
  }

  Future<void> _saveUserToFirestore(User? user, {String? name}) async {
    if (user == null) return;

    try {
      final userData = {
        'id': user.uid,
        'email': user.email,
        'name': name ?? user.displayName ?? '',
        'photoUrl': user.photoURL,
        'role': 0,
        'bosqueId': null,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await _firestore.collection('users').doc(user.uid).set(
            userData,
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Firestore save error: $e');
      throw Exception('Error guardando perfil en Firestore: $e');
    }
  }

  Future<bool> updateDisplayName(String name) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    try {
      await user.updateDisplayName(name);
      await _saveUserToFirestore(user, name: name);
      return true;
    } catch (_) {
      return false;
    }
  }

  UserModel? userModelFromFirebaseUser(User? user) {
    return _userFromFirebaseUser(user);
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      final trimmedEmail = email.trim();
      final methods =
          await _firebaseAuth.fetchSignInMethodsForEmail(trimmedEmail);
      debugPrint('Sign in methods for $trimmedEmail: $methods');

      if (methods.isEmpty) {
        debugPrint(
            'No sign-in methods found for $trimmedEmail, intentando envío directo de reset para confirmar.');
        try {
          await _firebaseAuth.sendPasswordResetEmail(email: trimmedEmail);
          return;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found' || e.code == 'invalid-email') {
            throw e;
          }
          rethrow;
        }
      }

      if (!methods.contains('password')) {
        final providerLabel =
            methods.contains('google.com') ? 'Google' : methods.join(', ');
        throw FirebaseAuthException(
          code: 'no-password-provider',
          message:
              'Esta cuenta está registrada con $providerLabel. Usa ese método para iniciar sesión.',
        );
      }

      await _firebaseAuth.sendPasswordResetEmail(email: trimmedEmail);
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'FirebaseAuthException in resetPassword: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in resetPassword: $e');
      rethrow;
    }
  }

  UserModel? _userFromFirebaseUser(User? user) {
    return user != null
        ? UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? '',
            photoUrl: user.photoURL,
            role: UserRole.campista,
            createdAt: user.metadata.creationTime ?? DateTime.now(),
            updatedAt: user.metadata.lastSignInTime ?? DateTime.now(),
          )
        : null;
  }
}
