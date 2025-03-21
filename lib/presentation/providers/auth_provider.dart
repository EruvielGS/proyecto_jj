import 'package:flutter/material.dart';
import 'package:proyecto_jj/data/models/user_model.dart';
import 'package:proyecto_jj/domain/use_cases/auth_use_case.dart';

class AuthProvider with ChangeNotifier {
  final AuthUseCase _authUseCase;

  AuthProvider(this._authUseCase);

  UserModel? _user;
  UserModel? get user => _user;

  Future<void> signIn(String email, String password) async {
    try {
      _user = await _authUseCase.signIn(email, password);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      _user = await _authUseCase.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authUseCase.signOut();
    _user = null;
    notifyListeners();
  }
}