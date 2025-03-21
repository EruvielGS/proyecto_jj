class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  // Convertir a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
    };
  }
}