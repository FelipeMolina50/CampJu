import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _errorCode;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;

  StreamSubscription<User?>? _authSubscription;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription =
        FirebaseAuth.instance.userChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        // Cargar datos completos del usuario desde Firestore
        final userData = await _loadUserData(firebaseUser.uid);
        
        if (userData != null) {
          // Sync email verification if Auth says verified but Firestore doesn't
          if (firebaseUser.emailVerified && !userData.emailVerified) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(firebaseUser.uid)
                .update({'emailVerified': true});
            _user = userData.copyWith(emailVerified: true);
          } else {
            _user = userData;
          }
        } else {
          // Usuario básico si no hay datos en Firestore
          _user = UserModel(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            emailVerified: firebaseUser.emailVerified,
            name: firebaseUser.displayName ?? '',
            apellidos: '', // Valor por defecto
            municipio: '', // Valor por defecto
            fechaNacimiento: DateTime.now(), // Valor por defecto
            tipoDocumento: 'CC', // Valor por defecto
            numeroDocumento: '', // Valor por defecto
            sexo: 'Masculino', // Valor por defecto
            telefono: '', // Valor por defecto
            eps: '', // Valor por defecto
            photoUrl: firebaseUser.photoURL,
            role: UserRole.campista,
            createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
            updatedAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
          );
        }
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  StreamSubscription<DocumentSnapshot>? _userStream;
  
  Future<UserModel?> _loadUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final userModel = UserModel.fromJson(doc.data()!);
        // Setup real-time listener
        _userStream?.cancel();
        _userStream = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            final updatedUser = UserModel.fromJson(snapshot.data()!);
            if (_user?.id == updatedUser.id) {
              _user = updatedUser;
              notifyListeners();
            }
          }
        });
        return userModel;
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
    return null;
  }

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  Future<Map<String, dynamic>> googleSignIn() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    Future<Map<String, dynamic>> signInFlow() async {
      debugPrint('Starting Google Sign In...');
      // Disconnect to force account selection
      await _googleSignIn
          .disconnect()
          .catchError((e) { debugPrint('Disconnect error: $e'); return null; });
      debugPrint('Disconnected from Google');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      debugPrint('Google Sign In result: $googleUser');

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'error': 'Inicio de sesión cancelado'};
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      debugPrint(
          'Google Auth: ${googleAuth.idToken != null ? 'idToken present' : 'no idToken'}');

      if (googleAuth.idToken == null) {
        throw Exception('No idToken de Google');
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('Signing in with Firebase...');
      final result = await _authService.googleLogin(credential);
      debugPrint('Firebase sign in result: $result');
      if (result['success'] == true) {
        _user = result['user'] as UserModel?;
        _isLoading = false;
        notifyListeners();
        return {
          'success': true,
          'isNewUser': result['isNewUser'] == true,
          'userName': _user?.name ?? '',
        };
      } else {
        _errorMessage = result['error'] ?? 'Error Google Sign In';
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'error': _errorMessage};
      }
    }

    try {
      return await signInFlow().timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          debugPrint('Google Sign In timed out');
          _errorMessage = 'Tiempo de espera agotado. Intenta de nuevo.';
          _isLoading = false;
          notifyListeners();
          return {'success': false, 'error': _errorMessage};
        },
      );
    } catch (e) {
      debugPrint('Google Sign In error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': _errorMessage};
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.login(email, password);
      if (result['success'] == true) {
        _user = result['user'] as UserModel?;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Error login';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.register(email, password, name);
      if (result['success'] == true) {
        _user = result['user'] as UserModel?;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Error registro';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUserName(String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final success = await _authService.updateDisplayName(name);
      if (success) {
        _user =
            _authService.userModelFromFirebaseUser(_authService.currentUser);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'No se pudo actualizar el nombre.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();
    try {
      final trimmedEmail = email.trim();

      // 1. Verificar en Firestore si el correo está registrado
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: trimmedEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _errorCode = 'user-not-found';
        _errorMessage = 'Este correo no está registrado.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Existe → enviar correo de recuperación
      await _authService.resetPassword(trimmedEmail);
      _errorCode = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorCode = e.code;
      _errorMessage = _authService.mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorCode = null;
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _authService.logout();
  }

  Future<bool> reauthenticate(String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.reauthenticate(password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authService.mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.deleteAccount();
      _user = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Método para determinar la ruta inicial basada en el estado del usuario
  String getInitialRoute() {
    if (_user == null) {
      return '/login';
    }

    // 1. Si email no está verificado → ir a verificar correo
    if (!_user!.emailVerified) {
      return '/verificar-correo';
    }

    // 2. Si perfil no está completo → ir a completar perfil
    if (!_user!.perfilCompleto) {
      return '/complete-profile';
    }

    // 3. Si todo ok → ir al home
    return '/home';
  }

  /// Fuerza la recarga de los datos del usuario desde Firestore
  Future<void> reloadUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final userData = await _loadUserData(firebaseUser.uid);
      if (userData != null) {
        _user = userData;
        notifyListeners();
      }
    }
  }

@override
  void dispose() {
    _authSubscription?.cancel();
    _userStream?.cancel();
    super.dispose();
  }
}
