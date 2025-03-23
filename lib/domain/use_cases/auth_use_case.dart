import 'dart:io';

import 'package:proyecto_jj/data/models/user_model.dart';
import 'package:proyecto_jj/data/repositories/auth_repository.dart';

class AuthUseCase {
  final AuthRepository _authRepository;

  AuthUseCase(this._authRepository);

  Future<UserModel?> signIn(String email, String password) async {
    return await _authRepository.signIn(email, password);
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    return await _authRepository.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  // Método para actualizar el perfil del usuario
  Future<UserModel?> updateUserProfile({
    required String uid,
    String? firstName,
    String? lastName,
  }) async {
    return await _authRepository.updateUserProfile(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
    );
  }

  // Método para actualizar el avatar del usuario con una imagen subida
  Future<UserModel?> updateUserAvatar({
    required String uid,
    required File imageFile,
  }) async {
    return await _authRepository.updateUserAvatar(
      uid: uid,
      imageFile: imageFile,
    );
  }

  // Método para actualizar el avatar personalizado (fluttermoji)
  Future<UserModel?> updateCustomAvatar({
    required String uid,
    required Map<String, dynamic> avatarData,
  }) async {
    return await _authRepository.updateCustomAvatar(
      uid: uid,
      avatarData: avatarData,
    );
  }
}
