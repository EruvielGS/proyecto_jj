class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatarUrl; // URL de imagen si se sube una foto
  final String? avatarType; // 'custom', 'uploaded', o null para el avatar por defecto
  final Map<String, dynamic>? avatarData; // Para guardar datos de fluttermoji

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.avatarType,
    this.avatarData,
  });

  // Convertir a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'avatarType': avatarType,
      'avatarData': avatarData,
    };
  }

  // Crear una copia del modelo con campos actualizados
  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? avatarType,
    Map<String, dynamic>? avatarData,
  }) {
    return UserModel(
      uid: this.uid,
      email: this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarType: avatarType ?? this.avatarType,
      avatarData: avatarData ?? this.avatarData,
    );
  }
}
