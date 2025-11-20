// lib/viewmodel/home/home_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:quitsmoking/data/models/smoke_log_model.dart';
import 'package:quitsmoking/data/repositories/smoke_log_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final SmokeLogRepository repo;
  final double expectedCostPerCig;
  final int expectedDailyIntake;

  StreamSubscription<List<SmokeLog>>? _logSub;
  Timer? _tickTimer;

  String? _currentUid;

  HomeBloc({
    required this.repo,
    required this.expectedCostPerCig,
    required this.expectedDailyIntake,
  }) : super(const HomeState()) {
    on<HomeStartListening>(_onStartListening);
    on<HomeLogsUpdated>(_onLogsUpdated);
    on<HomeAddSmokeLog>(_onAddSmokeLog);
    on<HomeDeleteSmokeLog>(_onDeleteSmokeLog);
    on<HomeTick>(_onTick);

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const HomeTick());
    });
  }

  Future<void> _onStartListening(
    HomeStartListening event,
    Emitter<HomeState> emit,
  ) async {
    _currentUid = event.uid;
    emit(state.copyWith(loading: true));

    await _logSub?.cancel();
    _logSub = repo
        .streamLogsForUser(event.uid)
        .listen(
          (logs) => add(HomeLogsUpdated(logs)),
          onError: (_) => emit(state.copyWith(loading: false)),
        );
  }

  Future<void> _onLogsUpdated(
    HomeLogsUpdated event,
    Emitter<HomeState> emit,
  ) async {
    final logs = event.logs;
    final now = DateTime.now();

    final startOfDay = DateTime(now.year, now.month, now.day);
    final todayLogs = logs
        .where((l) => l.timestamp.isAfter(startOfDay))
        .toList();

    final todaySpent = todayLogs.fold(0.0, (s, l) => s + l.cost);
    final todayCount = todayLogs.length;

    final expectedToday = expectedDailyIntake * expectedCostPerCig;
    final savedToday = (expectedToday - todaySpent).clamp(0.0, double.infinity);

    final sinceLast = logs.isNotEmpty
        ? now.difference(logs.first.timestamp)
        : Duration.zero;

    Duration longest = Duration.zero;
    if (logs.isNotEmpty) {
      for (int i = 0; i < logs.length - 1; i++) {
        final gap = logs[i].timestamp.difference(logs[i + 1].timestamp).abs();
        if (gap > longest) longest = gap;
      }
      final ongoing = now.difference(logs.first.timestamp);
      if (ongoing > longest) longest = ongoing;
    }

    final totalSpent = logs.fold(0.0, (s, l) => s + l.cost);

    emit(
      state.copyWith(
        logs: logs,
        sinceLast: sinceLast,
        longestCessation: longest,
        moneySpent: todaySpent,
        moneySaved: savedToday,
        todayCount: todayCount,
        totalSpent: totalSpent,
        loading: false,
      ),
    );
  }

  Future<void> _onAddSmokeLog(
    HomeAddSmokeLog event,
    Emitter<HomeState> emit,
  ) async {
    if (_currentUid == null) return;

    await repo.addLog(_currentUid!, cost: event.cost);
  }

  Future<void> _onDeleteSmokeLog(
    HomeDeleteSmokeLog event,
    Emitter<HomeState> emit,
  ) async {
    if (_currentUid == null) return;

    await repo.deleteLog(_currentUid!, event.logId);
  }

  Future<void> _onTick(HomeTick _, Emitter<HomeState> emit) async {
    if (state.logs.isEmpty) return;

    final now = DateTime.now();
    final sinceLast = now.difference(state.logs.first.timestamp);
    var longest = state.longestCessation;
    if (sinceLast > longest) longest = sinceLast;

    emit(state.copyWith(sinceLast: sinceLast, longestCessation: longest));
  }

  @override
  Future<void> close() {
    _logSub?.cancel();
    _tickTimer?.cancel();
    return super.close();
  }
}
