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

  // --- LOCAL COLOR PALETTE (Dark & Neon) ---
  final Color _bgBlack = const Color(0xFF000000);
  final Color _surfaceDark = const Color(0xFF151517);
  final Color _textWhite = const Color(0xFFFFFFFF);
  final Color _textGrey = const Color(0xFF8D8D8D);

  // Neon Accents
  final Color _neonPink = const Color(0xFFFF4FA6);
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
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Header
                      Text(
                        "Today's record",
                        style: GoogleFonts.poppins(
                          fontSize: 42, // Increased from 36
                          fontWeight: FontWeight.w700,
                          color: _textWhite,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateStr,
                        style: GoogleFonts.poppins(
                          fontSize: 24, // Increased from 22
                          color: _textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ---------------------------
                      // TIMER 1: CURRENT STREAK
                      // ---------------------------
                      Text(
                        "Since the last smoking",
                        style: GoogleFonts.lato(
                          fontSize: 20,
                          color: _textGrey,
                        ), // Increased from 16
                      ),
                      const SizedBox(height: 15),
                      _buildDetailedTimerRow(
                        state.sinceLast,
                        color: Colors.red,
                      ),

                      const SizedBox(height: 30),

                      // ---------------------------
                      // TIMER 2: LONGEST RECORD
                      // ---------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Longest cessation record",
                            style: GoogleFonts.lato(
                              fontSize: 20,
                              color: _textGrey,
                            ), // Increased from 16
                          ),
                          const Icon(
                            Icons.fireplace_sharp,
                            color: Colors.grey,
                            size: 22,
                          ), // Increased size
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildDetailedTimerRow(
                        state.longestCessation,
                        color: _neonGreen,
                      ),

                      const SizedBox(height: 40),

                      // ---------------------------
                      // MONEY STATS
                      // ---------------------------
                      Row(
                        children: [
                          _moneyStat(
                            "Money Spent",
                            state.moneySpent,
                            valueColor: _neonOrange,
                          ),
                          const SizedBox(width: 40),
                          _moneyStat(
                            "Money Saved",
                            state.moneySaved,
                            valueColor: _neonBlue,
                          ),
                        ],
                      ),

                      const Spacer(),

                      // ---------------------------
                      // BIG COUNTER
                      // ---------------------------
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 120,
                            right: 10,
                          ), // Adjusted padding
                          child: Text(
                            "${state.todayCount}",
                            style: GoogleFonts.poppins(
                              fontSize: 180, // Increased from 140
                              fontWeight: FontWeight.bold,
                              color: _textWhite,
                              height: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),

              // ---------------------------
              // FLOATING NAV BAR
              // ---------------------------
              Positioned(
                left: 20,
                right: 20,
                bottom: 30,
                child: Container(
                  height: 80, // Increased height from 75
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 60), // Space for FAB

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
              ),

              // ---------------------------
              // PLUS BUTTON
              // ---------------------------
              Positioned(
                left: 30,
                bottom: 55,
                child: GestureDetector(
                  onTap: () => _handleAddLog(context),
                  child: Container(
                    width: 90,
                    height: 90, // Increased from 85
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
                    ), // Increased icon size
                  ),
                ),
              ),

              // ---------------------------
              // MINUS BUTTON
              // ---------------------------
              Positioned(
                left: 130,
                bottom: 50,
                child: GestureDetector(
                  onTap: () => _handleDeleteLog(state),
                  child: Container(
                    width: 55,
                    height: 55, // Increased from 50
                    decoration: BoxDecoration(
                      color: _navBarColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12, width: 1),
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: Colors.white,
                      size: 30,
                    ), // Increased icon size
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
    int years = (d.inDays / 365).floor();
    int remainingDays = d.inDays % 365;
    int months = (remainingDays / 30).floor();
    int days = remainingDays % 30;
    int hours = d.inHours % 24;
    int minutes = d.inMinutes % 60;
    int seconds = d.inSeconds % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _timeUnit(years, "Year", color),
        _timeUnit(months, "Month", color),
        _timeUnit(days, "Day", color),
        _timeUnit(hours, "Hour", color),
        _timeUnit(minutes, "Min", color),
        _timeUnit(seconds, "Sec", color),
      ],
    );
  }

  Widget _timeUnit(int value, String label, Color color) {
    return Column(
      children: [
        Text(
          "$value",
          style: GoogleFonts.poppins(
            fontSize: 29, // Increased from 22
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 12)],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 13, // Increased from 10
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
          style: GoogleFonts.lato(fontSize: 18, color: _textGrey),
        ), // Increased from 14
        const SizedBox(height: 4),
        Text(
          "₹${value.toStringAsFixed(0)}",
          style: GoogleFonts.robotoMono(
            fontSize: 34, // Increased from 24
            color: valueColor,
            fontWeight: FontWeight.bold,
            shadows: [
              BoxShadow(color: valueColor.withOpacity(0.4), blurRadius: 8),
            ],
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
          Icon(icon, color: _textGrey, size: 30), // Increased from 26
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: _textGrey, fontSize: 12),
          ), // Increased from 10
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
