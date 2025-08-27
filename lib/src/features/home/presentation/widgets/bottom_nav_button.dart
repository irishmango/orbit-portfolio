import 'package:flutter/material.dart';
import 'package:orbit/src/features/create/presentation/create_screen.dart';

class BottomNavButton extends StatelessWidget {
  final IconData icon;
  final double radius;
  final VoidCallback? onTap;

  const BottomNavButton({
    super.key,
    required this.icon,
    this.radius = 30,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateScreen()),
            );
          },
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(254, 203, 93, 1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black),
      ),
    );
  }
}