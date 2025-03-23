import 'dart:io';

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

  // Método para actualizar el perfil del usuario
  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
  }) async {
    try {
      if (_user == null) throw Exception('No hay usuario autenticado');
      
      _user = await _authUseCase.updateUserProfile(
        uid: _user!.uid,
        firstName: firstName,
        lastName: lastName,
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Método para actualizar el avatar del usuario con una imagen subida
  Future<void> updateUserAvatar(File imageFile) async {
    try {
      if (_user == null) throw Exception('No hay usuario autenticado');
      
      _user = await _authUseCase.updateUserAvatar(
        uid: _user!.uid,
        imageFile: imageFile,
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Método para actualizar el avatar personalizado (fluttermoji)
  Future<void> updateCustomAvatar(Map<String, dynamic> avatarData) async {
    try {
      if (_user == null) throw Exception('No hay usuario autenticado');
      
      _user = await _authUseCase.updateCustomAvatar(
        uid: _user!.uid,
        avatarData: avatarData,
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}