import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:orbit/auth_repository.dart';
import 'package:orbit/src/features/auth/presentation/login_screen.dart';
import 'package:orbit/src/features/auth/presentation/verification_screen.dart';
import 'package:orbit/src/features/home/presentation/home_screen.dart';
import 'package:orbit/src/models/database_repository.dart';
import 'package:orbit/src/models/firestore_repository.dart';
import 'package:orbit/theme.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {

  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        final User? currentUser = snapshot.data;

        if (currentUser != null) {
          currentUser.reload().catchError((_) {
            FirebaseAuth.instance.signOut();
          });
        }

        return MaterialApp(
          key: Key('${snapshot.data?.uid ?? 'no_user_id'}${(snapshot.data?.emailVerified ?? false).toString()}'),
          theme: primaryTheme,
          home: _getScreen(currentUser),
        );
      },
    );
  }

  Widget _getScreen(User? currentUser) {
    if (currentUser == null) {
      return LoginScreen();
    } else if (!currentUser.emailVerified) {
      return EmailVerificationScreen();
    } else {
      return HomeScreen();
    }
  }
}
