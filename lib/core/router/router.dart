// lib/core/router/router.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quitsmoking/view/screens/history/history_screen.dart';
import 'package:quitsmoking/view/screens/settings/settings_screen.dart';

import 'package:quitsmoking/view/screens/splash_screen.dart';
import 'package:quitsmoking/view/screens/login_screen.dart';
import 'package:quitsmoking/view/screens/onboarding_screen.dart';
import 'package:quitsmoking/view/screens/home_screen.dart';

import 'package:quitsmoking/viewmodel/auth/auth_bloc.dart';
import 'package:quitsmoking/viewmodel/auth/auth_state.dart';

// NEW IMPORTS
import 'package:quitsmoking/viewmodel/home/home_bloc.dart';
import 'package:quitsmoking/data/repositories/smoke_log_repository.dart';

GoRouter createAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // ---------------------------
      // 🚀 HOME ROUTE WITH HomeBloc
      // ---------------------------
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final st = context.read<AuthBloc>().state;

          if (st is! AuthAuthenticated) {
            // Safety fallback
            return const LoginScreen();
          }

          final user = st.user;

          final cigsPerPack = user.cigarettesPerPack ?? 1;
          final costPerCig = (user.packCost ?? 0.0) / cigsPerPack;
          final expectedDaily = user.dailyIntake ?? 5;

          return BlocProvider(
            create: (_) => HomeBloc(
              repo: SmokeLogRepository(),
              expectedCostPerCig: costPerCig,
              expectedDailyIntake: expectedDaily,
            ),
            child: const HomeScreen(),
          );
        },
      ),
    ],
    redirect: (context, state) {
      final st = authBloc.state;
      final loc = state.uri.toString();

      // 1. Splash screen for initialization
      if (st is AuthUninitialized || st is AuthLoading) {
        return loc == '/splash' ? null : '/splash';
      }

      // 2. User not authenticated
      if (st is AuthUnauthenticated) {
        return loc == '/login' ? null : '/login';
      }

      // 3. User authenticated but not onboarded
      if (st is AuthFirstTime) {
        return loc == '/onboarding' ? null : '/onboarding';
      }

      // 4. User authenticated AND onboarded
      if (st is AuthAuthenticated) {
        if (loc == '/splash' || loc == '/login' || loc == '/onboarding') {
          return '/home';
        }
        return null;
      }

      return null;
    },
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _sub;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
