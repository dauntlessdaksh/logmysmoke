import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quitsmoking/viewmodel/auth/auth_event.dart';
import 'package:quitsmoking/viewmodel/auth/auth_state.dart';
import 'package:quitsmoking/data/repositories/auth_repository.dart';
import 'package:quitsmoking/data/models/user_model.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthUninitialized()) {
    on<AppStarted>(_onAppStarted);
    on<SignInRequested>(_onSignIn);
    on<SignOutRequested>(_onSignOut);
    on<OnboardingCompleted>(_onOnboardingCompleted);
  }

  Future<void> _onAppStarted(AppStarted _, Emitter<AuthState> emit) async {
    emit(AuthUninitialized());
    await Future.delayed(const Duration(milliseconds: 60));
    emit(AuthLoading());
    try {
      final user = await authRepository.getCurrentUser();
      if (user == null) {
        emit(AuthUnauthenticated());
        return;
      }
      // If Firestore doc indicates user is fully onboarded -> Authenticated
      if (user.fullyOnboarded) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthFirstTime());
      }
    } catch (e) {
      emit(AuthError('Failed to initialize: ${e.toString()}'));
    }
  }

  Future<void> _onSignIn(SignInRequested _, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final res = await authRepository.signInWithGoogle();
      if (res == null) {
        emit(AuthUnauthenticated());
        return;
      }
      final user = res.user;
      if (res.isNewUser || !user.fullyOnboarded) {
        emit(AuthFirstTime());
      } else {
        emit(AuthAuthenticated(user));
      }
    } catch (e) {
      emit(AuthError('Sign-in failed: ${e.toString()}'));
    }
  }

  Future<void> _onSignOut(SignOutRequested _, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Sign-out failed: ${e.toString()}'));
    }
  }

  Future<void> _onOnboardingCompleted(
    OnboardingCompleted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final current = await authRepository.getCurrentUser();
      if (current == null) {
        emit(AuthUnauthenticated());
        return;
      }

      final updated = current.copyWith(
        motivations: event.motivations,
        dailyIntake: event.dailyIntake,
        cigarettesPerPack: event.cigarettesPerPack,
        packCost: event.packCost,
        notificationsEnabled: event.notificationsEnabled,
        isFullyOnboarded: true,
      );

      // Save to Firestore and mark onboarded
      await authRepository.saveUser(updated, markOnboarded: true);

      emit(AuthAuthenticated(updated));
    } catch (e) {
      emit(AuthError('Saving onboarding failed: ${e.toString()}'));
    }
  }
}
