// lib/viewmodel/home/home_event.dart
import 'package:equatable/equatable.dart';
import 'package:quitsmoking/data/models/smoke_log_model.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

// Start realtime listener for logs
class HomeStartListening extends HomeEvent {
  final String uid;
  const HomeStartListening(this.uid);
  @override
  List<Object?> get props => [uid];
}

// Logs stream update
class HomeLogsUpdated extends HomeEvent {
  final List<SmokeLog> logs;
  const HomeLogsUpdated(this.logs);
  @override
  List<Object?> get props => [logs];
}

// Add log (+)
class HomeAddSmokeLog extends HomeEvent {
  final double cost;
  const HomeAddSmokeLog(this.cost);
  @override
  List<Object?> get props => [cost];
}

// Delete most recent log (-)
class HomeDeleteSmokeLog extends HomeEvent {
  final String logId;
  const HomeDeleteSmokeLog(this.logId);
  @override
  List<Object?> get props => [logId];
}

// Tick for timer updates
class HomeTick extends HomeEvent {
  const HomeTick();
}
