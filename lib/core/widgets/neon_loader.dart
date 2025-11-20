import 'package:flutter/material.dart';
import 'package:quitsmoking/core/theme/app_colors.dart';

/// Public NeonLoader widget (not private)
class NeonLoader extends StatelessWidget {
  const NeonLoader({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.6),
            blurRadius: 25,
            spreadRadius: 3,
          ),
        ],
      ),
      child: CircularProgressIndicator(
        strokeWidth: 4,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
    );
  }
}
