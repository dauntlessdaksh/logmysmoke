// lib/view/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:quitsmoking/core/theme/app_colors.dart';
import 'package:quitsmoking/viewmodel/history/history_bloc.dart';
import 'package:quitsmoking/viewmodel/history/history_event.dart';
import 'package:quitsmoking/viewmodel/history/history_state.dart';
import 'package:quitsmoking/data/models/smoke_log_model.dart';
import 'package:quitsmoking/viewmodel/auth/auth_bloc.dart';
import 'package:quitsmoking/viewmodel/auth/auth_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryBloc historyBloc;

  @override
  void initState() {
    super.initState();
    historyBloc = context.read<HistoryBloc>();

    // Start listening using current authenticated user
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      historyBloc.add(HistoryStartListening(authState.user.uid));
    }
  }

  String _formatTime(DateTime ts) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return "${two(ts.hour)}:${two(ts.minute)}:${two(ts.second)}";
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceDark,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                context.go('/home');
              },
            ),
            title: const Text("History", style: TextStyle(color: Colors.white)),
          ),
          body: Column(
            children: [
              // Calendar
              Container(
                color: AppColors.surfaceBlack,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: state.selectedDate,
                  selectedDayPredicate: (d) =>
                      d.year == state.selectedDate.year &&
                      d.month == state.selectedDate.month &&
                      d.day == state.selectedDate.day,
                  onDaySelected: (selectedDay, focusedDay) {
                    historyBloc.add(HistoryDateSelected(selectedDay));
                  },
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppColors.neonBlue,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: AppColors.neonGreen,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: const TextStyle(color: Colors.white70),
                    weekendTextStyle: const TextStyle(color: Colors.white70),
                    outsideTextStyle: const TextStyle(color: Colors.white24),
                  ),
                ),
              ),

              // result summary
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      "${state.logsForSelectedDate.length} cigarettes",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    if (state.logsForSelectedDate.isEmpty)
                      const Text(
                        '(no logs)',
                        style: TextStyle(color: Colors.white54),
                      ),
                  ],
                ),
              ),

              // list (index + time only)
              Expanded(
                child: state.loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: state.logsForSelectedDate.length,
                        itemBuilder: (context, idx) {
                          final log = state.logsForSelectedDate[idx];
                          // show index increasing from 1 (oldest) or descending? We'll show newest first (idx 0 newest) so index reflects reverse order.
                          final displayIndex =
                              state.logsForSelectedDate.length - idx;
                          final ts = log.timestamp;
                          return Card(
                            color: AppColors.surfaceDark,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                "Cigarette #$displayIndex",
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: Text(
                                _formatTime(ts),
                                style: const TextStyle(color: Colors.white70),
                              ),
                              // no price shown as requested
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
