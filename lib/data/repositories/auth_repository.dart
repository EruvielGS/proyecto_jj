import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:proyecto_jj/data/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _getUserFromFirestore(userCredential.user!.uid);
    } catch (e) {
      throw e;
    }
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardar datos adicionales en Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
      });

      return UserModel(
        uid: userCredential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<UserModel?> _getUserFromFirestore(String uid) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      return UserModel(
        uid: uid,
        email: data['email'],
        firstName: data['firstName'],
        lastName: data['lastName'],
        avatarUrl: data['avatarUrl'],
        avatarType: data['avatarType'],
        avatarData: data['avatarData'],
      );
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Método para restablecer contraseña
  Future<void> resetPassword(String email) async {
    try {
      print('Enviando correo de recuperación a: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('Correo de recuperación enviado correctamente');
    } catch (e) {
      print('Error al enviar correo de recuperación: $e');
      // Proporcionar mensajes de error más específicos
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw Exception(
                'No hay usuario registrado con este correo electrónico');
          case 'invalid-email':
            throw Exception('El formato del correo electrónico no es válido');
          case 'too-many-requests':
            throw Exception('Demasiados intentos. Inténtalo más tarde');
          default:
            throw Exception('Error al enviar correo: ${e.message}');
        }
      } else {
        throw e;
      }
    }
  }

  // Método para actualizar el perfil del usuario
  Future<UserModel?> updateUserProfile({
    required String uid,
    String? firstName,
    String? lastName,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;

      await _firestore.collection('users').doc(uid).update(updateData);

      return _getUserFromFirestore(uid);
    } catch (e) {
      throw e;
    }
  }

  // Método para actualizar el avatar del usuario con una imagen subida
  Future<UserModel?> updateUserAvatar({
    required String uid,
    required File imageFile,
  }) async {
    try {
      // Obtener la extensión del archivo
      String extension = imageFile.path.split('.').last.toLowerCase();
      if (extension.isEmpty) extension = 'jpg'; // Default si no hay extensión

      // Crear la referencia en Storage asegurando que las carpetas existan
      String fileName =
          'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}.$extension';
      Reference storageRef = _storage.ref().child(fileName);

      // Configurar los metadatos para aceptar cualquier tipo de imagen
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/$extension',
      );

      // Subir imagen a Firebase Storage con los metadatos
      await storageRef.putFile(imageFile, metadata);
      String downloadUrl = await storageRef.getDownloadURL();

      // Actualizar datos en Firestore
      await _firestore.collection('users').doc(uid).update({
        'avatarUrl': downloadUrl,
        'avatarType': 'uploaded',
      });

      return _getUserFromFirestore(uid);
    } catch (e) {
      print('Error al subir imagen: $e');
      throw e;
    }
  }

  // Método para actualizar el avatar personalizado (fluttermoji)
  Future<UserModel?> updateCustomAvatar({
    required String uid,
    required Map<String, dynamic> avatarData,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'avatarData': avatarData,
        'avatarType': 'custom',
      });

      return _getUserFromFirestore(uid);
    } catch (e) {
      throw e;
    }
  }
}
