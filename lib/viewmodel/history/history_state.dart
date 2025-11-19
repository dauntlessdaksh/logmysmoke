// lib/viewmodel/history/history_state.dart
import 'package:equatable/equatable.dart';
import 'package:quitsmoking/data/models/smoke_log_model.dart';

class HistoryState extends Equatable {
  final DateTime selectedDate;
  final List<SmokeLog> allLogs;
  final List<SmokeLog> logsForSelectedDate;
  final bool loading;

  const HistoryState({
    required this.selectedDate,
    this.allLogs = const [],
    this.logsForSelectedDate = const [],
    this.loading = false,
  });

  factory HistoryState.initial() {
    final today = DateTime.now();
    final selected = DateTime(today.year, today.month, today.day);
    return HistoryState(selectedDate: selected);
  }

  HistoryState copyWith({
    DateTime? selectedDate,
    List<SmokeLog>? allLogs,
    List<SmokeLog>? logsForSelectedDate,
    bool? loading,
  }) {
    return HistoryState(
      selectedDate: selectedDate ?? this.selectedDate,
      allLogs: allLogs ?? this.allLogs,
      logsForSelectedDate: logsForSelectedDate ?? this.logsForSelectedDate,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [
    selectedDate,
    allLogs,
    logsForSelectedDate,
    loading,
  ];
}
