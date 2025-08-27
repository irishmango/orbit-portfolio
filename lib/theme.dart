import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF000000);
  static const card = Color(0xFF1F1F1F);
  static const accent = Color.fromRGBO(28, 125, 28, 1);
  static const white = Colors.white;
  static const white54 = Colors.white54;
  static const red = Colors.red;
  static const green = Colors.green;
  static const amber = Colors.amber;
  static const orange = Colors.orange;
  static final grey900 = Colors.grey[900]!;
  static final grey800 = Colors.grey[800]!;
  static const cursor = Color.fromRGBO(28, 125, 28, 1);
}

class AppTextStyles {
  static const header = TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.white);
  static const title = TextStyle(fontSize: 34, color: AppColors.white);
  static const body = TextStyle(color: AppColors.white, fontSize: 16);
  static const hint = TextStyle(color: AppColors.white54);
  static const button = TextStyle(color: AppColors.white, fontSize: 16);
}

class AppDecorations {
  static final card = BoxDecoration(
    color: const Color.fromARGB(255, 23, 23, 23),
    borderRadius: BorderRadius.circular(12),
  );
  static final input = BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(12),
  );
}

class AppPaddings {
  static const screen = EdgeInsets.all(16);
  static const card = EdgeInsets.all(12);
  static const input = EdgeInsets.all(20);
}

final ThemeData primaryTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.background,
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: AppColors.cursor,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.white,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.white,
      textStyle: AppTextStyles.button,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    hintStyle: AppTextStyles.hint,
    border: InputBorder.none,
  ),
);