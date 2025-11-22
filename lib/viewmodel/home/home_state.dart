// lib/viewmodel/home/home_state.dart
import 'package:equatable/equatable.dart';
import 'package:quitsmoking/data/models/smoke_log_model.dart';

class HomeState extends Equatable {
  final List<SmokeLog> logs;

  final Duration sinceLast;
  final Duration longestCessation;

  final double moneySpent; // today
  final double moneySaved; // today
  final int todayCount; // today
  final double totalSpent; // all time

  final bool loading;

  const HomeState({
    this.logs = const [],
    this.sinceLast = Duration.zero,
    this.longestCessation = Duration.zero,
    this.moneySpent = 0.0,
    this.moneySaved = 0.0,
    this.todayCount = 0,
    this.totalSpent = 0.0,
    this.loading = false,
  });

  HomeState copyWith({
    List<SmokeLog>? logs,
    Duration? sinceLast,
    Duration? longestCessation,
    double? moneySpent,
    double? moneySaved,
    int? todayCount,
    double? totalSpent,
    bool? loading,
  }) {
    return HomeState(
      logs: logs ?? this.logs,
      sinceLast: sinceLast ?? this.sinceLast,
      longestCessation: longestCessation ?? this.longestCessation,
      moneySpent: moneySpent ?? this.moneySpent,
      moneySaved: moneySaved ?? this.moneySaved,
      todayCount: todayCount ?? this.todayCount,
      totalSpent: totalSpent ?? this.totalSpent,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [
        logs,
        sinceLast,
        longestCessation,
        moneySpent,
        moneySaved,
        todayCount,
        totalSpent,
        loading,
      ];
}
