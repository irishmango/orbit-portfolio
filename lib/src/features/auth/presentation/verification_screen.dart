import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:orbit/src/features/home/presentation/home_screen.dart';
import 'package:orbit/theme.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  bool _isLoading = false;

  Future<void> _checkVerificationStatus() async {
    setState(() => _isLoading = true);
    await FirebaseAuth.instance.currentUser?.reload();
    final isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    setState(() {
      _isEmailVerified = isVerified;
      _isLoading = false;
    });

    if (_isEmailVerified && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _resendEmail() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification email sent.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppPaddings.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Verify your email', style: AppTextStyles.header),
              const SizedBox(height: 8),
              Text(
                "We’ve sent a verification link to your email. Open the link to verify your account, "
                "then return to the app and tap the button below.",
                style: AppTextStyles.body.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 20),

              // status card
              Container(
                decoration: AppDecorations.card.copyWith(
                  border: Border.all(color: AppColors.white54, width: 1),
                ),
                padding: AppPaddings.card,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _isEmailVerified ? Icons.mark_email_read_rounded : Icons.mark_email_unread_rounded,
                      color: _isEmailVerified ? AppColors.green : AppColors.amber,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEmailVerified ? 'Email verified' : 'Awaiting verification',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isEmailVerified ? AppColors.green : AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isEmailVerified
                                ? 'You can now continue into the app.'
                                : 'Check your inbox (and spam) for the verification email.',
                            style: AppTextStyles.hint,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkVerificationStatus,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : const Text('I have verified'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: const BorderSide(color: AppColors.white54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: AppTextStyles.button,
                  ),
                  onPressed: _resendEmail,
                  child: const Text('Resend verification email'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Didn’t get it? Make sure your email is correct and try again.",
                  style: AppTextStyles.hint,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}