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
    on<HomeTick>(_onTick);

    // periodic tick updates sinceLast & longest (runs every second)
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
          (logs) {
            add(HomeLogsUpdated(logs));
          },
          onError: (err) {
            print('HomeBloc stream error: $err');
            emit(state.copyWith(loading: false));
          },
        );
  }

  Future<void> _onLogsUpdated(
    HomeLogsUpdated event,
    Emitter<HomeState> emit,
  ) async {
    final logs = event.logs;
    final now = DateTime.now();

    // moneySpent (sum all logs)
    final spent = logs.fold<double>(0.0, (s, l) => s + l.cost);

    // sinceLast: time since newest log (logs sorted newest first by stream)
    final sinceLast = logs.isNotEmpty
        ? now.difference(logs.first.timestamp)
        : Duration.zero;

    // longest cessation: compute gaps between consecutive logs, include ongoing sinceLast
    Duration longest = Duration.zero;
    if (logs.isNotEmpty) {
      for (int i = 0; i < logs.length - 1; i++) {
        final newer = logs[i].timestamp;
        final older = logs[i + 1].timestamp;
        final gap = newer.difference(older).abs();
        if (gap > longest) longest = gap;
      }
      final ongoing = now.difference(logs.first.timestamp);
      if (ongoing > longest) longest = ongoing;
    }

    // today count and today spent
    final startOfDay = DateTime(now.year, now.month, now.day);
    final todayLogs = logs
        .where((l) => l.timestamp.isAfter(startOfDay))
        .toList();
    final todayCount = todayLogs.length;
    final todaySpent = todayLogs.fold<double>(0.0, (s, l) => s + l.cost);

    // expected today vs actual -> moneySaved (simple UX: expected - actual, clamp >= 0)
    final expectedToday = expectedDailyIntake * expectedCostPerCig;
    final savedToday = (expectedToday - todaySpent).clamp(0.0, double.infinity);

    emit(
      state.copyWith(
        logs: logs,
        sinceLast: sinceLast,
        longestCessation: longest,
        moneySpent: spent,
        moneySaved: savedToday,
        todayCount: todayCount,
        loading: false,
      ),
    );
  }

  Future<void> _onAddSmokeLog(
    HomeAddSmokeLog event,
    Emitter<HomeState> emit,
  ) async {
    if (_currentUid == null) {
      print(
        'HomeAddSmokeLog: no uid set – call HomeStartListening(uid) first.',
      );
      return;
    }
    try {
      await repo.addLog(_currentUid!, cost: event.cost);
      // stream will automatically push the new log; HomeLogsUpdated will run
    } catch (err) {
      print('Add smoke log failed: $err');
    }
  }

  Future<void> _onTick(HomeTick event, Emitter<HomeState> emit) async {
    // only update timers when we have logs
    if (state.logs.isEmpty) return;

    final now = DateTime.now();
    final sinceLast = now.difference(state.logs.first.timestamp);
    var longest = state.longestCessation;
    if (sinceLast > longest) longest = sinceLast;

    // emit only durations changed (we emit anyway for simplicity)
    emit(state.copyWith(sinceLast: sinceLast, longestCessation: longest));
  }

  @override
  Future<void> close() {
    _logSub?.cancel();
    _tickTimer?.cancel();
    return super.close();
  }
}
