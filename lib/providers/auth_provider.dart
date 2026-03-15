import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../service/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  String get userName => _user?.displayName ?? 'Cricket Fan';
  String get userPhoto => _user?.photoURL ?? '';
  String get userId => _user?.uid ?? '';

  AuthProvider() {
    AuthService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;

    final User? user = await AuthService.signInWithGoogle();

    if (user != null) {
      _user = user;
      _setLoading(false);
      return true;
    } else {
      _error = 'Sign in cancelled or failed. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    await AuthService.signOut();
    _user = null;
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
