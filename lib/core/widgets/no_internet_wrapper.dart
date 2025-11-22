import 'dart:ui'; // Required for ImageFilter
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoInternetWrapper extends StatefulWidget {
  final Widget child;

  const NoInternetWrapper({super.key, required this.child});

  @override
  State<NoInternetWrapper> createState() => _NoInternetWrapperState();
}

class _NoInternetWrapperState extends State<NoInternetWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Neon Red Color
  final Color _neonRed = const Color(0xFFFF2A2A);

  @override
  void initState() {
    super.initState();
    // Creates a breathing/pulsing animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final connectivityList = snapshot.data;

        // Logic to check offline status
        bool isOffline = connectivityList == null ||
            connectivityList.isEmpty ||
            connectivityList.contains(ConnectivityResult.none);

        return Stack(
          children: [
            // 1. THE APP CONTENT (Blocked when offline)
            AbsorbPointer(
              absorbing: isOffline,
              child: widget.child,
            ),

            // 2. THE NEON OFFLINE OVERLAY
            if (isOffline)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: child,
                    );
                  },
                  child: Stack(
                    children: [
                      // A. Frosted Glass Effect
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                        child: Container(
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),

                      // B. Centered Content
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Animated Pulsing Icon
                              AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                      border: Border.all(
                                        color: _neonRed.withOpacity(0.6),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _neonRed.withOpacity(
                                              0.2 + (0.3 * _controller.value)),
                                          blurRadius:
                                              20 + (10 * _controller.value),
                                          spreadRadius: 5 * _controller.value,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.wifi_off_rounded,
                                        size: 40,
                                        color: _neonRed,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 40),

                              // Title
                              Text(
                                "CONNECTION LOST",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  shadows: [
                                    BoxShadow(
                                      color: _neonRed.withOpacity(0.8),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Subtitle
                              Text(
                                "You are currently offline.\nReconnect to continue logging.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Small loader indicating "Searching"
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _neonRed,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Reconnecting...",
                                style: GoogleFonts.robotoMono(
                                  color: _neonRed,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
