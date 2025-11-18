import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quitsmoking/view/screens/login_screen.dart';
import 'package:quitsmoking/view/screens/onboarding_screen.dart';
import 'package:quitsmoking/view/screens/home_screen.dart';
import 'package:quitsmoking/view/screens/splash_screen.dart';
import 'package:quitsmoking/viewmodel/auth/auth_bloc.dart';
import 'package:quitsmoking/viewmodel/auth/auth_state.dart';

GoRouter createAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
    ],
    redirect: (context, state) {
      final st = authBloc.state;
      final loc = state.uri.toString();

      if (st is AuthLoading || st is AuthUninitialized) {
        return loc == '/splash' ? null : '/splash';
      }

      if (st is AuthUnauthenticated) {
        return loc == '/login' ? null : '/login';
      }

      if (st is AuthFirstTime) {
        return loc == '/onboarding' ? null : '/onboarding';
      }

      if (st is AuthAuthenticated) {
        // if user is authenticated but still on /onboarding, send to home
        if (loc == '/onboarding') return '/home';
        return loc == '/home' ? null : '/home';
      }

      return null;
    },
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListener = () => notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListener());
  }
  late final VoidCallback notifyListener;
  late final StreamSubscription _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
