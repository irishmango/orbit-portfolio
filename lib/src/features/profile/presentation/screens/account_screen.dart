import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orbit/theme.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName ?? 'No name set';
    final email = user?.email ?? 'No email';
    final memberSince = user?.metadata.creationTime != null
        ? '${user!.metadata.creationTime!.day}/${user.metadata.creationTime!.month}/${user.metadata.creationTime!.year}'
        : 'Unknown';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        centerTitle: true,
        title: const Text('Account', style: AppTextStyles.header),
      ),
      body: Padding(
        padding: AppPaddings.input,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: AppPaddings.card,
              width: double.infinity,
              decoration: AppDecorations.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: $displayName', style: AppTextStyles.body),
                  const SizedBox(height: 8),
                  Text('Email: $email', style: AppTextStyles.body),
                  const SizedBox(height: 8),
                  Text('Member since: $memberSince', style: AppTextStyles.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}