import 'package:flutter/material.dart';
import 'package:orbit/theme.dart';

class ReportProblemScreen extends StatelessWidget {
  const ReportProblemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        centerTitle: true,
        title: const Text('Report a Problem', style: AppTextStyles.body),
      ),
      body: Padding(
        padding: AppPaddings.input,
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              cursorColor: AppColors.accent,
              maxLines: 10,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: "Describe the issue you're having...",
                hintStyle: AppTextStyles.hint,
                filled: true,
                fillColor: AppColors.grey900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Submit logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.grey800,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Submit', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}