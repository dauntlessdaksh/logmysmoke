import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:quitsmoking/viewmodel/auth/auth_bloc.dart';
import 'package:quitsmoking/viewmodel/auth/auth_state.dart';
import 'package:quitsmoking/viewmodel/home/home_bloc.dart';
import 'package:quitsmoking/viewmodel/home/home_event.dart';
import 'package:quitsmoking/viewmodel/home/home_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeBloc _homeBloc;
  Timer? _timer;

  // --- LOCAL COLOR PALETTE ---
  final Color _bgBlack = const Color(0xFF000000);
  final Color _textWhite = const Color(0xFFFFFFFF);
  final Color _textGrey = const Color(0xFF8D8D8D);

  final Color _neonGreen = const Color(0xFF3BF37C);
  final Color _neonOrange = const Color(0xFFFF7A33);
  final Color _neonBlue = const Color(0xFF47B6FF);

  final Color _navBarColor = const Color(0xFF1E1E20);

  @override
  void initState() {
    super.initState();
    _homeBloc = context.read<HomeBloc>();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _homeBloc.add(HomeStartListening(authState.user.uid));
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat("dd MMM yyyy").format(DateTime.now());

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: _bgBlack,
          body: Stack(
            children: [
              // 1. MAIN CONTENT (NO SCROLL - FIT TO SCREEN)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Header
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Today's record",
                          style: GoogleFonts.poppins(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: _textWhite,
                            height: 1.1,
                          ),
                        ),
                      ),
                      Text(
                        dateStr,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          color: _textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const Spacer(flex: 1), // Dynamic Space

                      // TIMER 1
                      Text(
                        "Since the last smoking",
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: _textGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailedTimerRow(
                        state.sinceLast,
                        color: Colors.red,
                      ),

                      const Spacer(flex: 1), // Dynamic Space

                      // TIMER 2
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Longest cessation record",
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: _textGrey,
                            ),
                          ),
                          const Icon(
                            Icons.fireplace_sharp,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDetailedTimerRow(
                        state.longestCessation,
                        color: _neonGreen,
                      ),

                      const Spacer(flex: 1), // Dynamic Space

                      // MONEY STATS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _moneyStat(
                            "Money Spent",
                            state.moneySpent,
                            valueColor: _neonOrange,
                          ),
                          _moneyStat(
                            "Money Saved",
                            state.moneySaved,
                            valueColor: _neonBlue,
                          ),
                        ],
                      ),

                      const Spacer(flex: 1),

                      // BIG COUNTER (Expanded to fill remaining area)
                      Expanded(
                        flex: 4,
                        child: Container(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            alignment: Alignment.centerRight,
                            child: Text(
                              "${state.todayCount}",
                              style: GoogleFonts.poppins(
                                fontSize: 180, // Max size, will scale down
                                fontWeight: FontWeight.bold,
                                color: _textWhite,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // --- FIX: RIGID BOTTOM SPACING ---
                      // This SizedBox pushes the Column content UP.
                      // 80 (NavBar) + 30 (Bottom Position) + 30 (Buffer) = 140
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),

              // 2. FLOATING NAV BAR
              Positioned(
                left: 20,
                right: 20,
                bottom: 30,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: _navBarColor,
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Reserved space for buttons (Plus + Minus)
                      const SizedBox(width: 180),

                      // Nav Items
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _navIcon(
                              Icons.calendar_month_rounded,
                              "History",
                              () => context.push('/history'),
                            ),
                            _navIcon(
                              Icons.settings_outlined,
                              "Settings",
                              () => context.push('/settings'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. PLUS BUTTON
              Positioned(
                left: 30,
                bottom: 55,
                child: GestureDetector(
                  onTap: () => _handleAddLog(context),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
              ),

              // 4. MINUS BUTTON
              Positioned(
                left: 135,
                bottom: 55,
                child: GestureDetector(
                  onTap: () => _handleDeleteLog(state),
                  child: Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2C),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.8),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.15),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildDetailedTimerRow(Duration d, {required Color color}) {
    // FittedBox ensures the timer row shrinks if the screen is too narrow
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 48, // Full width constraint
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _timeUnit((d.inDays / 365).floor(), "Year", color),
            _timeUnit((d.inDays % 365) ~/ 30, "Month", color),
            _timeUnit((d.inDays % 365) % 30, "Day", color),
            _timeUnit(d.inHours % 24, "Hour", color),
            _timeUnit(d.inMinutes % 60, "Min", color),
            _timeUnit(d.inSeconds % 60, "Sec", color),
          ],
        ),
      ),
    );
  }

  Widget _timeUnit(int value, String label, Color color) {
    return Column(
      children: [
        Text(
          "$value",
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 12)],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            color: _textGrey,
          ),
        ),
      ],
    );
  }

  Widget _moneyStat(String label, double value, {required Color valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(fontSize: 16, color: _textGrey),
        ),
        const SizedBox(height: 4),
        // FittedBox prevents money from wrapping or overflowing
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "₹${value.toStringAsFixed(0)}",
            style: GoogleFonts.robotoMono(
              fontSize: 30,
              color: valueColor,
              fontWeight: FontWeight.bold,
              shadows: [
                BoxShadow(color: valueColor.withOpacity(0.4), blurRadius: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _navIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _textGrey, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: _textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _handleAddLog(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      final packCost = user.packCost ?? 0.0;
      final packSize = user.cigarettesPerPack ?? 20;
      final costPerCig = (packSize > 0) ? (packCost / packSize) : 0.0;
      _homeBloc.add(HomeAddSmokeLog(costPerCig));
    }
  }

  void _handleDeleteLog(HomeState state) {
    if (state.logs.isNotEmpty) {
      final lastLog = state.logs.first;
      _homeBloc.add(HomeDeleteSmokeLog(lastLog.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Removed last cigarette log"),
          duration: Duration(milliseconds: 800),
        ),
      );
    }
  }
}
