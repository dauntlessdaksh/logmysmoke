// lib/viewmodel/home/home_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:quitsmoking/data/models/smoke_log_model.dart';
import 'package:quitsmoking/data/repositories/smoke_log_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

/// HomeBloc responsibilities:
/// - subscribe to smoke log stream for current user (realtime)
/// - compute sinceLast, longest cessation, moneySpent (today), moneySaved (today)
/// - maintain a periodic timer (tick every second) to update durations
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final SmokeLogRepository repo;

  /// expected cost per cigarette and expected daily intake (from user's onboarding)
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
            // leave previous state, but mark loading false
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

    // totalSpent (all logs)
    final totalSpent = logs.fold<double>(0.0, (s, l) => s + l.cost);

    // get start of current day (local)
    final startOfDay = DateTime(now.year, now.month, now.day);

    // FILTER today's logs (timestamp strictly after startOfDay)
    final todayLogs = logs
        .where((l) => l.timestamp.isAfter(startOfDay))
        .toList();

    final todaySpent = todayLogs.fold<double>(0.0, (s, l) => s + l.cost);
    final todayCount = todayLogs.length;

    // Money saved today: expectedToday - todaySpent (clamped to >= 0)
    final expectedToday = expectedDailyIntake * expectedCostPerCig;
    final savedToday = (expectedToday - todaySpent).clamp(0.0, double.infinity);

    // sinceLast: difference between now and newest log timestamp (logs ordered newest first)
    final sinceLast = logs.isNotEmpty
        ? now.difference(logs.first.timestamp)
        : Duration.zero;

    // compute longest cessation: iterate logs and compute durations between consecutive logs
    Duration longest = Duration.zero;
    if (logs.isNotEmpty) {
      for (int i = 0; i < logs.length - 1; i++) {
        final newer = logs[i].timestamp;
        final older = logs[i + 1].timestamp;
        final gap = newer.difference(older).abs();
        if (gap > longest) longest = gap;
      }
      // also consider ongoing (time since last smoke)
      final ongoing = now.difference(logs.first.timestamp);
      if (ongoing > longest) longest = ongoing;
    }

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
    if (_currentUid == null) {
      print(
        'HomeAddSmokeLog: no current uid set. Call HomeStartListening(uid) first.',
      );
      return;
    }
    try {
      await repo.addLog(_currentUid!, cost: event.cost);
      // stream will push new logs; _onLogsUpdated will handle calculations
    } catch (err) {
      print('Add smoke log error: $err');
    }
  }

  Future<void> _onDeleteSmokeLog(
    HomeDeleteSmokeLog event,
    Emitter<HomeState> emit,
  ) async {
    if (_currentUid == null) {
      print('HomeDeleteSmokeLog: no current uid set.');
      return;
    }
    try {
      await repo.deleteLog(_currentUid!, event.logId);
      // stream will push new logs; _onLogsUpdated will handle recalculation
    } catch (err) {
      print('Delete log error: $err');
    }
  }

  Future<void> _onTick(HomeTick _, Emitter<HomeState> emit) async {
    // Only update running durations if there is at least one log
    if (state.logs.isEmpty) return;

    final now = DateTime.now();
    final sinceLast = now.difference(state.logs.first.timestamp);
    var longest = state.longestCessation;
    if (sinceLast > longest) longest = sinceLast;

    // emit updated durations
    emit(state.copyWith(sinceLast: sinceLast, longestCessation: longest));
  }

  @override
  Future<void> close() {
    _logSub?.cancel();
    _tickTimer?.cancel();
    return super.close();
  }
}
