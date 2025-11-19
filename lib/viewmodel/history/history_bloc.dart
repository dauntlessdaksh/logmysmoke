// lib/viewmodel/history/history_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:quitsmoking/data/models/smoke_log_model.dart';
import 'package:quitsmoking/data/repositories/smoke_log_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final SmokeLogRepository repo;
  StreamSubscription<List<SmokeLog>>? _sub;

  HistoryBloc({required this.repo}) : super(HistoryState.initial()) {
    on<HistoryStartListening>(_onStartListening);
    on<HistoryLogsUpdated>(_onLogsUpdated);
    on<HistoryDateSelected>(_onDateSelected);
  }

  Future<void> _onStartListening(
    HistoryStartListening e,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    await _sub?.cancel();
    _sub = repo
        .streamLogsForUser(e.uid)
        .listen(
          (logs) {
            add(HistoryLogsUpdated(logs));
          },
          onError: (err) {
            print('HistoryBloc stream error: $err');
            emit(state.copyWith(loading: false));
          },
        );
  }

  Future<void> _onLogsUpdated(
    HistoryLogsUpdated e,
    Emitter<HistoryState> emit,
  ) async {
    final logs = e.logs;
    final filtered = _filterByDate(logs, state.selectedDate);
    emit(
      state.copyWith(
        allLogs: logs,
        logsForSelectedDate: filtered,
        loading: false,
      ),
    );
  }

  Future<void> _onDateSelected(
    HistoryDateSelected e,
    Emitter<HistoryState> emit,
  ) async {
    final selected = DateTime(e.date.year, e.date.month, e.date.day);
    final filtered = _filterByDate(state.allLogs, selected);
    emit(state.copyWith(selectedDate: selected, logsForSelectedDate: filtered));
  }

  List<SmokeLog> _filterByDate(List<SmokeLog> logs, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return logs
        .where((l) => l.timestamp.isAfter(start) && l.timestamp.isBefore(end))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // newest first
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
