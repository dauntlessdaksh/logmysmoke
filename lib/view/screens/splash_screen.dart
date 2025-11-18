import 'package:flutter/material.dart';
import 'package:quitsmoking/core/theme/app_colors.dart';
import 'package:quitsmoking/core/widgets/neon_loader.dart';
import 'package:quitsmoking/core/widgets/neon_loader.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: NeonLoader()),
    );
  }
}
