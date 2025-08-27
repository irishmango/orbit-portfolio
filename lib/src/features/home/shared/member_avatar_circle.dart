import 'package:flutter/material.dart';

class AvatarCircle extends StatelessWidget {
  final String initials;
  final String? image;            
  final double size;
  final double borderWidth;

  const AvatarCircle({
    super.key,
    required this.initials,
    this.image,
    this.size = 28,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null && image!.trim().isNotEmpty;

    Widget _initials() => Center(
          child: Text(
            initials,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: size * 0.43, 
              letterSpacing: 0.2,
            ),
          ),
        );

    Widget _image() => ClipOval(
          child: Image.network(
            image!,
            width: size,
            height: size,
            fit: BoxFit.cover,
        
            errorBuilder: (_, __, ___) => _initials(),
          ),
        );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: borderWidth),
      ),
      child: hasImage ? _image() : _initials(),
    );
  }
}