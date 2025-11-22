import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quitsmoking/viewmodel/auth/auth_bloc.dart';
import 'package:quitsmoking/viewmodel/auth/auth_event.dart';
import 'package:quitsmoking/viewmodel/auth/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  final Color _bgBlack = const Color(0xFF000000);
  final Color _surfaceDark = const Color(0xFF151517);
  final Color _textWhite = const Color(0xFFFFFFFF);
  final Color _textGrey = const Color(0xFF8D8D8D);
  final Color _neonPink = const Color(0xFFFF4FA6);
  final Color _neonBlue = const Color(0xFF47B6FF);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (c, s) {
        if (s is AuthError) {
          ScaffoldMessenger.of(c).showSnackBar(
            SnackBar(
              content: Text(s.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _bgBlack,
        body: Stack(
          children: [
            // Background Gradient Spot
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withOpacity(0.15),
                  backgroundBlendMode: BlendMode.screen,
                ),
              ),
            ),

            // CHANGED: LayoutBuilder pattern for safe centering + scrolling
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40), // Top Padding

                            // Logo / Title
                            Expanded(
                              // Pushes content to center
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.2),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/icon.png',
                                      width: 150,
                                      height: 150,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'logmy',
                                        style: GoogleFonts.poppins(
                                          color: _textWhite,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -1.0,
                                        ),
                                      ),
                                      Text(
                                        'smoke',
                                        style: GoogleFonts.poppins(
                                          color: Colors.red,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Track. Improve. Quit forever.',
                                    style: GoogleFonts.lato(
                                      color: _textGrey,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Google Sign In Button
                            GestureDetector(
                              onTap: () => context
                                  .read<AuthBloc>()
                                  .add(SignInRequested()),
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _surfaceDark,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _neonBlue.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.login,
                                        color: Colors.white),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.poppins(
                                        color: _textWhite,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Terms
                            Text(
                              'By continuing, you agree to our Terms & Privacy Policy',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                color: _textGrey.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 40), // Bottom Padding
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Loading Overlay
            BlocBuilder<AuthBloc, AuthState>(
              builder: (_, state) {
                if (state is AuthLoading) {
                  return Container(
                    color: Colors.black.withOpacity(0.8),
                    child: Center(
                      child: CircularProgressIndicator(color: _neonPink),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
