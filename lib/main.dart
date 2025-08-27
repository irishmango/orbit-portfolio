import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:orbit/app.dart';
import 'package:orbit/auth_repository.dart';
import 'package:orbit/firebase_auth_repository.dart';
import 'package:orbit/src/models/firestore_repository.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<FirestoreRepository>(create: (_) => FirestoreRepository()),
        Provider<AuthRepository>(create: (_) => FirebaseAuthRepository()),
      ],
      child: const App(),
    ),
  );
}