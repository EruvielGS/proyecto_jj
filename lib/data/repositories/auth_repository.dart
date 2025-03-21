import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_jj/data/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
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
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return UserModel(
        uid: uid,
        email: userDoc['email'],
        firstName: userDoc['firstName'],
        lastName: userDoc['lastName'],
      );
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}