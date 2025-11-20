// lib/view/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:quitsmoking/core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();

    // HomeBloc should be provided by MultiBlocProvider (MyApp)
    _homeBloc = context.read<HomeBloc>();

    // Start listening using authenticated user's uid
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _homeBloc.add(HomeStartListening(authState.user.uid));
    } else {
      // Not authenticated - optional redirect:
      // context.go('/login');
    }
  }

  @override
  void dispose() {
    // Do NOT close HomeBloc here (it's provided higher in the tree)
    super.dispose();
  }

  /// format duration for UI:
  /// - if >= 365 days -> "Yy Mmo Dd HH:MM:SS"
  /// - else if >= 30 days -> "Mmo Dd HH:MM:SS"
  /// - else if >= 1 day -> "Dd HH:MM:SS"
  /// - else -> "HH:MM:SS" or "MM:SS" depending on hours presence
  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');

    final totalSeconds = d.inSeconds;
    final days = totalSeconds ~/ (24 * 3600);
    final hours = (totalSeconds % (24 * 3600)) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (days >= 365) {
      final years = days ~/ 365;
      final months = (days % 365) ~/ 30;
      final remDays = (days % 365) % 30;
      return "${years}y ${months}mo ${remDays}d ${two(hours)}:${two(minutes)}:${two(seconds)}";
    } else if (days >= 30) {
      final months = days ~/ 30;
      final remDays = days % 30;
      return "${months}mo ${remDays}d ${two(hours)}:${two(minutes)}:${two(seconds)}";
    } else if (days > 0) {
      return "${days}d ${two(hours)}:${two(minutes)}:${two(seconds)}";
    } else if (hours > 0) {
      return "${two(hours)}:${two(minutes)}:${two(seconds)}";
    } else {
      return "${two(minutes)}:${two(seconds)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's record",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formattedToday(),
                    style: const TextStyle(fontSize: 22, color: Colors.white54),
                  ),
                  const SizedBox(height: 20),

                  _label("Since last smoking"),
                  Text(
                    _format(state.sinceLast),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),
                  _label("Longest smoking cessation time"),
                  Text(
                    _format(state.longestCessation),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statCard(
                        "Money Spent",
                        "₹${state.moneySpent.toStringAsFixed(2)}",
                      ),
                      _statCard(
                        "Money Saved (today)",
                        "₹${state.moneySaved.toStringAsFixed(2)}",
                      ),
                      _statCard("Cigs Today", "${state.todayCount}"),
                    ],
                  ),

                  const Spacer(),

                  Center(
                    child: GestureDetector(
                      onTap: () {
                        final authState = context.read<AuthBloc>().state;
                        if (authState is! AuthAuthenticated) {
                          context.go('/login');
                          return;
                        }

                        // compute cost per cigarette from UserModel
                        final user = authState.user;
                        final pack = user.cigarettesPerPack ?? 1;
                        final costPerCig = (user.packCost ?? 0.0) / pack;

                        context.read<HomeBloc>().add(
                          HomeAddSmokeLog(costPerCig),
                        );
                      },
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.neonPink,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonPink.withOpacity(0.28),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.add, size: 48, color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Tap + to log a cigarette",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _bottomNav(context),
        );
      },
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, color: Colors.white54),
    );
  }

  Widget _statCard(String title, String value) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _bottomNavigationBarItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
    bool active, {
    bool usePush = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (usePush) {
          context.push(route);
        } else {
          context.go(route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? Colors.redAccent : Colors.white54),
          Text(
            label,
            style: TextStyle(color: active ? Colors.redAccent : Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    // Note: this is simple, adapt active state detection as per your router
    return Container(
      height: 70,
      color: AppColors.surfaceDark,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bottomNavigationBarItem(context, Icons.home, "Home", "/home", true),
          _bottomNavigationBarItem(
            context,
            Icons.history,
            "History",
            "/history",
            GoRouter.of(context).routerDelegate.currentConfiguration.fullPath ==
                "/history",
          ),
          _bottomNavigationBarItem(
            context,
            Icons.settings,
            "Settings",
            "/settings",
            GoRouter.of(context).routerDelegate.currentConfiguration.fullPath ==
                "/settings",
          ),
        ],
      ),
    );
  }

  String _formattedToday() {
    final now = DateTime.now();
    return "${now.day} ${_month(now.month)} ${now.year}";
  }

  String _month(int m) {
    const names = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return names[m - 1];
  }
}
