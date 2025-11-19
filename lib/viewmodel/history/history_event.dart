// lib/viewmodel/history/history_event.dart
import 'package:equatable/equatable.dart';
import 'package:quitsmoking/data/models/smoke_log_model.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

/// Start listening to the user's logs (same repo stream used by Home)
class HistoryStartListening extends HistoryEvent {
  final String uid;
  const HistoryStartListening(this.uid);
  @override
  List<Object?> get props => [uid];
}

/// Fire when the stream of all logs updates (we'll filter by selected date)
class HistoryLogsUpdated extends HistoryEvent {
  final List<SmokeLog> logs;
  const HistoryLogsUpdated(this.logs);
  @override
  List<Object?> get props => [logs];
}

/// When user picks a date on calendar
class HistoryDateSelected extends HistoryEvent {
  final DateTime date;
  const HistoryDateSelected(this.date);
  @override
  List<Object?> get props => [date];
}
