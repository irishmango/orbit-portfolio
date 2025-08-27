import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:orbit/auth_repository.dart';
import 'package:orbit/src/features/profile/presentation/screens/account_screen.dart';
import 'package:orbit/src/features/profile/presentation/screens/report_problem_screen.dart';
import 'package:orbit/src/features/profile/presentation/screens/settings_screen.dart';
import 'package:orbit/src/models/firestore_repository.dart';
import 'package:orbit/theme.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppColors.white),
        ),
        content: const Text(
          'This will permanently remove your account and all associated data.',
          style: TextStyle(color: AppColors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showBlockingLoader(BuildContext context, {String? message}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.background,
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  backgroundColor: AppColors.card,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message ?? 'Please wait...',
                  style: const TextStyle(color: AppColors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccountFlow(BuildContext context) async {
    final authRepo = context.read<AuthRepository>();
    final db = context.read<FirestoreRepository>(); // now provided correctly
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No signed-in user found.')),
      );
      return;
    }

    final confirmed = await _confirmDelete(context);
    if (!confirmed) return;

    _showBlockingLoader(context, message: 'Deleting your account...');

    String? errorText;
    try {
      // 1) Delete Firestore data
      await db.deleteAppUser(uid);

      // 2) Delete Firebase Auth user (may require recent login)
      try {
        await authRepo.deleteCurrentUser();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          errorText =
              'For security, please log in again to confirm deletion. We signed you out.';
        } else {
          errorText = 'Auth deletion failed: ${e.message ?? e.code}';
        }
      }

      // 3) Sign out regardless
      await authRepo.signOut();
    } catch (e) {
      errorText = 'Failed to delete account: $e';
    } finally {
      Navigator.of(context, rootNavigator: true).pop(); // close loader
    }

    if (errorText != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully')),
      );
    }

    // TODO: Navigate to your login/landing screen
    // Navigator.of(context).pushAndRemoveUntil(
    //   MaterialPageRoute(builder: (_) => const LoginScreen()),
    //   (_) => false,
    // );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        centerTitle: true,
        title: Text(userName, style: AppTextStyles.title),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Stack(
            children: [
              CircleAvatar(
                radius: 100,
                backgroundColor: AppColors.grey800,
                backgroundImage: AssetImage('assets/default_profile.png'),
              ),
              Positioned(
                bottom: 0,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    // TODO: Navigate to edit profile screen
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromARGB(255, 23, 23, 23),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(8),
                    child:
                        const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Padding(
            padding: AppPaddings.input,
            child: Column(
              children: [
                ProfileOptionButton(
                  text: "Account",
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AccountScreen()),
                    );
                  },
                ),
                ProfileOptionButton(
                  text: "Settings",
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const ProfileOptionButton(text: "FAQ"),
                ProfileOptionButton(
                  text: "Report a Problem",
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ReportProblemScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'Version 1.0.0, Build 1.0.0',
            style: TextStyle(
                color: Color.fromARGB(255, 104, 104, 104), fontSize: 14),
          ),
          const Spacer(),
          Padding(
            padding: AppPaddings.input,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await auth.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Logged out successfully')),
                        );
                        // TODO: Navigate to login screen here
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grey800,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Log out', style: AppTextStyles.button),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _deleteAccountFlow(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child:
                          Text('Delete Account', style: AppTextStyles.button),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class ProfileOptionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const ProfileOptionButton({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: AppDecorations.card,
        width: double.infinity,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}