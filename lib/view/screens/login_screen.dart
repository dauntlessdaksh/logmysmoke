import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quitsmoking/core/theme/app_colors.dart';
import 'package:quitsmoking/core/widgets/neon_loader.dart';
import 'package:quitsmoking/viewmodel/auth/auth_bloc.dart';
import 'package:quitsmoking/viewmodel/auth/auth_event.dart';
import 'package:quitsmoking/viewmodel/auth/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _showNetworkError(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text('Network error. Please check your internet connection.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (c, s) {
        if (s is AuthError) {
          ScaffoldMessenger.of(
            c,
          ).showSnackBar(SnackBar(content: Text(s.message)));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'logmysmoke',
                        style: TextStyle(
                          color: AppColors.logoPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '.',
                        style: TextStyle(
                          color: AppColors.logoDot,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Track. Improve. Quit forever.',
                    style: TextStyle(color: AppColors.greyText),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GestureDetector(
                      onTap: () =>
                          context.read<AuthBloc>().add(SignInRequested()),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonBlue.withOpacity(0.32),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.login, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: AppColors.softWhite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),

              // global loading overlay
              BlocBuilder<AuthBloc, AuthState>(
                builder: (_, state) {
                  if (state is AuthLoading) {
                    return const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black87,
                        child: Center(child: NeonLoader()),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
