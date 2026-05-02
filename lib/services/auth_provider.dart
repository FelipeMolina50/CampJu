import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
        FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _user = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? '',
          photoUrl: firebaseUser.photoURL,
          role: UserRole.campista,
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          updatedAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
        );
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  Future<Map<String, dynamic>> googleSignIn() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    Future<Map<String, dynamic>> signInFlow() async {
      print('Starting Google Sign In...');
      // Disconnect to force account selection
      await _googleSignIn
          .disconnect()
          .catchError((e) => print('Disconnect error: $e'));
      print('Disconnected from Google');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('Google Sign In result: $googleUser');

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'error': 'Inicio de sesión cancelado'};
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print(
          'Google Auth: ${googleAuth.idToken != null ? 'idToken present' : 'no idToken'}');

      if (googleAuth.idToken == null) {
        throw Exception('No idToken de Google');
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Signing in with Firebase...');
      final result = await _authService.googleLogin(credential);
      print('Firebase sign in result: $result');
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
          print('Google Sign In timed out');
          _errorMessage = 'Tiempo de espera agotado. Intenta de nuevo.';
          _isLoading = false;
          notifyListeners();
          return {'success': false, 'error': _errorMessage};
        },
      );
    } catch (e) {
      print('Google Sign In error: $e');
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
      await _authService.resetPassword(email);
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

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
