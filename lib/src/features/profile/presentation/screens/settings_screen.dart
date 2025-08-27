import 'package:flutter/material.dart';
import 'package:orbit/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        centerTitle: true,
        title: const Text('Settings', style: AppTextStyles.header),
      ),
      body: Padding(
        padding: AppPaddings.input,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account settings
            Container(
              padding: AppPaddings.card,
              width: double.infinity,
              decoration: AppDecorations.card,
              child: const Text('Account', style: AppTextStyles.body),
            ),
            const SizedBox(height: 10),
            // Notifications settings
            Container(
              padding: AppPaddings.card,
              width: double.infinity,
              decoration: AppDecorations.card,
              child: const Text('Notifications', style: AppTextStyles.body),
            ),
            const SizedBox(height: 10),
            // Appearance settings
            Container(
              padding: AppPaddings.card,
              width: double.infinity,
              decoration: AppDecorations.card,
              child: const Text('Appearance', style: AppTextStyles.body),
            ),
            const SizedBox(height: 10),
            // Task defaults
            Container(
              padding: AppPaddings.card,
              width: double.infinity,
              decoration: AppDecorations.card,
              child: const Text('Task Defaults', style: AppTextStyles.body),
            ),
            const SizedBox(height: 10),
            // Backup & sync
            Container(
              padding: AppPaddings.card,
              width: double.infinity,
              decoration: AppDecorations.card,
              child: const Text('Backup & Sync', style: AppTextStyles.body),
            ),
            const SizedBox(height: 10),
            // Privacy & security
            Container(
              padding: AppPaddings.card,
              width: double.infinity,
              decoration: AppDecorations.card,
              child: const Text('Privacy & Security', style: AppTextStyles.body),
            ),
            const SizedBox(height: 10),
            // Help & support
            Container(
              padding: AppPaddings.card,
              width: double.infinity,
              decoration: AppDecorations.card,
              child: const Text('Help & Support', style: AppTextStyles.body),
            ),
          ],
        ),
      ),
    );
  }
}