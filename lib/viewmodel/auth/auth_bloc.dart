import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quitsmoking/data/models/user_model.dart';
import 'package:quitsmoking/data/repositories/auth_repository.dart';
import 'package:quitsmoking/data/services/notification_service.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthUninitialized()) {
    on<AppStarted>(_onAppStarted);
    on<SignInRequested>(_onSignIn);
    on<SignOutRequested>(_onSignOut);
    on<OnboardingCompleted>(_onOnboardingCompleted);
  }

  // -------------------------------------------------------
  // APP STARTED
  // -------------------------------------------------------
  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthUninitialized());

    await Future.delayed(const Duration(milliseconds: 60));
    emit(AuthLoading());

    try {
      final user = await authRepository.getCurrentUser();

      if (user == null) {
        emit(AuthUnauthenticated());
        return;
      }

      // --- FIXED: Ensure token is up-to-date for returning users ---
      try {
        await NotificationService.saveTokenToFirestore(user.uid);
      } catch (e) {
        // Don't block login if token fails, just log it
        print("Non-fatal error updating token on app start: $e");
      }
      // -----------------------------------------------------------

      if (user.fullyOnboarded) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthFirstTime());
      }
    } catch (e) {
      emit(AuthError("Failed to initialize: ${e.toString()}"));
    }
  }

  // -------------------------------------------------------
  // GOOGLE SIGN-IN
  // -------------------------------------------------------
  Future<void> _onSignIn(SignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final res = await authRepository.signInWithGoogle();

      if (res == null) {
        emit(AuthUnauthenticated());
        return;
      }

      final user = res.user;

      // Save FCM token immediately after login
      await NotificationService.saveTokenToFirestore(user.uid);

      if (res.isNewUser || !user.fullyOnboarded) {
        emit(AuthFirstTime());
      } else {
        emit(AuthAuthenticated(user));
      }
    } catch (e) {
      emit(AuthError("Sign-in failed: ${e.toString()}"));
    }
  }

  // -------------------------------------------------------
  // SIGN OUT
  // -------------------------------------------------------
  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Optional: Remove token on sign out to stop notifications for this device
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        await NotificationService.removeTokenFromFirestore(user.uid);
      }

      await authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError("Sign-out failed: ${e.toString()}"));
    }
  }

  // -------------------------------------------------------
  // ONBOARDING COMPLETED
  // -------------------------------------------------------
  Future<void> _onOnboardingCompleted(
    OnboardingCompleted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final currentUser = await authRepository.getCurrentUser();

      if (currentUser == null) {
        emit(AuthUnauthenticated());
        return;
      }

      final updated = currentUser.copyWith(
        motivations: event.motivations,
        dailyIntake: event.dailyIntake,
        cigarettesPerPack: event.cigarettesPerPack,
        packCost: event.packCost,
        notificationsEnabled: event.notificationsEnabled,
        isFullyOnboarded: true,
      );

      // Save onboarding data to Firestore
      await authRepository.saveUser(updated, markOnboarded: true);

      // Update notification token
      if (event.notificationsEnabled) {
        await NotificationService.saveTokenToFirestore(updated.uid);
      } else {
        await NotificationService.removeTokenFromFirestore(updated.uid);
      }

      emit(AuthAuthenticated(updated));
    } catch (e) {
      emit(AuthError("Saving onboarding failed: ${e.toString()}"));
    }
  }
}
