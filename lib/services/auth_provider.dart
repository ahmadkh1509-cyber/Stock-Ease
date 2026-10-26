import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_services.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  StreamSubscription<User?>? _sub;

  User? _user;
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _sub = _service.authStateChanges.listen((user) {
      _user = user;
      _isInitializing = false;
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) {
    return _run(() => _service.signIn(email, password));
  }

  Future<bool> signUp(String name, String email, String password) {
    return _run(() => _service.signUp(name, email, password));
  }

  Future<bool> sendResetEmail(String email) {
    return _run(() => _service.resetPassword(email));
  }

  Future<void> logout() => _service.signOut();

  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      return false;
    } catch (_) {
      _errorMessage = 'something wrong happened, try again';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email or password is wrong';
      case 'email-already-in-use':
        return 'already registered ';
      case 'weak-password':
        return ' weak password ';
      case 'invalid-email':
        return 'incorrect password';
      case 'network-request-failed':
        return 'Internet connection error';
      case 'too-many-requests':
        return 'too many tries try again after sometime';
      case 'user-disabled':
        return 'this account is disable ';
      default:
        return 'Error: $code';
    }
  }

  @override
  void dispose() {
    _sub?.cancel(); // stream band karna zaroori hai
    super.dispose();
  }
}
