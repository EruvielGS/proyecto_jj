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
}
