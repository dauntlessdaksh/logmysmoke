// lib/viewmodel/home/home_state.dart
import 'package:equatable/equatable.dart';
import 'package:quitsmoking/data/models/smoke_log_model.dart';

class HomeState extends Equatable {
  final List<SmokeLog> logs;

  /// Time since last smoke (ongoing)
  final Duration sinceLast;

  /// Longest cessation observed (including ongoing)
  final Duration longestCessation;

  /// Money spent TODAY (calculated from logs after midnight)
  final double moneySpent;

  /// Money saved TODAY (expectedToday - todaySpent clamped >= 0)
  final double moneySaved;

  /// Number of cigarettes smoked TODAY
  final int todayCount;

  /// Total (all-time) money spent (kept for reference)
  final double totalSpent;

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
