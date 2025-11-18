import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:quitsmoking/core/theme/app_colors.dart';
import 'package:quitsmoking/viewmodel/auth/auth_bloc.dart';
import 'package:quitsmoking/viewmodel/auth/auth_event.dart';
import 'package:quitsmoking/viewmodel/auth/auth_state.dart';
import 'package:quitsmoking/core/widgets/neon_loader.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  int _navIndex(String loc) {
    if (loc.startsWith('/progress')) return 1;
    if (loc.startsWith('/logs')) return 2;
    if (loc.startsWith('/notifications')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    String name = 'User';
    if (state is AuthAuthenticated) name = state.user.displayName ?? 'User';

    final loc = GoRouterState.of(context).uri.toString();
    final idx = _navIndex(loc);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Row(
                    children: [
                      Text(
                        'logmysmoke',
                        style: TextStyle(
                          color: AppColors.logoPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '.',
                        style: TextStyle(
                          color: AppColors.logoDot,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        context.read<AuthBloc>().add(SignOutRequested()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.6),
                          width: 1.2,
                        ),
                        color: Colors.red.withOpacity(0.12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.logout, color: Colors.redAccent, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hello, $name',
              style: const TextStyle(
                color: AppColors.softWhite,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'NON-SMOKER FOR',
              style: TextStyle(
                color: AppColors.neonPink,
                fontSize: 14,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _TimeUnit(value: '0', label: 'Years'),
                _TimeUnit(value: '0', label: 'Months'),
                _TimeUnit(value: '3', label: 'Days'),
                _TimeUnit(value: '5', label: 'Hours'),
                _TimeUnit(value: '40', label: 'Minutes'),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                children: const [
                  DashboardCard(
                    title: "Today's Expenses",
                    value: "₹50",
                    color: AppColors.neonOrange,
                  ),
                  DashboardCard(
                    title: "Money Saved",
                    value: "₹162",
                    color: AppColors.neonBlue,
                  ),
                  DashboardCard(
                    title: "Non-Smoked Cigs",
                    value: "16",
                    color: AppColors.neonGreen,
                  ),
                  DashboardCard(
                    title: "Life Gained (hrs)",
                    value: "5",
                    color: AppColors.neonPink,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(context, idx),
    );
  }

  Widget _bottomNav(BuildContext ctx, int i) => Container(
    height: 70,
    decoration: const BoxDecoration(color: AppColors.background),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _navItem(ctx, Icons.home, i == 0, AppColors.neonOrange, '/home'),
        _navItem(
          ctx,
          Icons.show_chart,
          i == 1,
          AppColors.neonGreen,
          '/progress',
        ),
        _navItem(ctx, Icons.list, i == 2, AppColors.neonBlue, '/logs'),
        _navItem(
          ctx,
          Icons.notifications,
          i == 3,
          AppColors.neonPink,
          '/notifications',
        ),
      ],
    ),
  );

  Widget _navItem(
    BuildContext ctx,
    IconData icon,
    bool active,
    Color c,
    String route,
  ) => GestureDetector(
    onTap: () => ctx.go(route),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? c.withOpacity(0.22) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: active ? c : AppColors.softWhite, size: 24),
    ),
  );
}

class _TimeUnit extends StatelessWidget {
  final String value;
  final String label;
  const _TimeUnit({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.softWhite,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.greyText, fontSize: 12),
        ),
      ],
    ),
  );
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const DashboardCard({
    required this.title,
    required this.value,
    required this.color,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.35),
          blurRadius: 18,
          spreadRadius: 0.5,
        ),
      ],
    ),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(color: AppColors.greyText, fontSize: 13),
        ),
      ],
    ),
  );
}
