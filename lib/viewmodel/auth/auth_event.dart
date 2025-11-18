import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class SignInRequested extends AuthEvent {}

class SignOutRequested extends AuthEvent {}

class OnboardingCompleted extends AuthEvent {
  final List<String> motivations;
  final int dailyIntake;
  final int cigarettesPerPack;
  final double packCost;
  final bool notificationsEnabled;

  const OnboardingCompleted({
    required this.motivations,
    required this.dailyIntake,
    required this.cigarettesPerPack,
    required this.packCost,
    required this.notificationsEnabled,
  });

  @override
  List<Object?> get props => [
    motivations,
    dailyIntake,
    cigarettesPerPack,
    packCost,
    notificationsEnabled,
  ];
}
