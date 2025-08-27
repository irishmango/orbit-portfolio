import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orbit/auth_repository.dart';


class FirebaseAuthRepository implements AuthRepository {
  @override
    Future<void> registerUser(String email, String password) async {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _ensureUserInFirestore(credential.user);
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _ensureUserInFirestore(credential.user);
  }

  Future<void> _ensureUserInFirestore(User? user) async {
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> addUserToFirestore() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

  @override
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Stream<User?> authStateChanges() {
    return FirebaseAuth.instance.authStateChanges();
  }
  
  @override
  Future<void> sendPasswordResetEmail(String email) {
    // TODO: implement sendPasswordResetEmail
    throw UnimplementedError();
  }
  
  @override
  Future<void> signInWithGoogle() async {
    // Web
    if (kIsWeb) {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({
        'prompt': 'select_account',  
      });

    final cred = await FirebaseAuth.instance.signInWithPopup(provider);
    await _ensureUserInFirestore(cred.user);
    return;
  }

    // ios&android
    await GoogleSignIn.instance.initialize();

    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    await _ensureUserInFirestore(userCredential.user);
    final user = userCredential.user;

    if (user != null) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'displayName': user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
  
  @override
Future<void> sendVerificationEmail() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && !user.emailVerified) {
    await user.sendEmailVerification();
  }
}

  @override
  Future<void> deleteCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No signed-in user');

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        rethrow;
      }
      rethrow;
    }
  }

}