import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:quitsmoking/viewmodel/history/history_bloc.dart';
import 'package:quitsmoking/viewmodel/history/history_event.dart';
import 'package:quitsmoking/viewmodel/history/history_state.dart';
import 'package:quitsmoking/viewmodel/auth/auth_bloc.dart';
import 'package:quitsmoking/viewmodel/auth/auth_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryBloc historyBloc;

  // --- LOCAL COLOR PALETTE (Dark & Neon) ---
  final Color _bgBlack = const Color(0xFF000000);
  final Color _surfaceDark = const Color(0xFF151517);
  final Color _textWhite = const Color(0xFFFFFFFF);
  final Color _textGrey = const Color(0xFF8D8D8D);

  // Neon Accents
  final Color _neonPink = Colors.redAccent;
  final Color _neonGreen = Colors.red;
  final Color _neonOrange = const Color(0xFFFF7A33);

  @override
  void initState() {
    super.initState();
    historyBloc = context.read<HistoryBloc>();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      historyBloc.add(HistoryStartListening(authState.user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: _bgBlack,
          appBar: AppBar(
            backgroundColor: _bgBlack,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => context.go('/home'),
            ),
            centerTitle: true,
            title: Text(
              "History",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: _textWhite,
              ),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              // 1. CALENDAR SECTION
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  decoration: BoxDecoration(
                    color: _surfaceDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    focusedDay: state.selectedDate,
                    currentDay: DateTime.now(),
                    selectedDayPredicate: (d) =>
                        isSameDay(state.selectedDate, d),
                    onDaySelected: (selectedDay, focusedDay) {
                      historyBloc.add(HistoryDateSelected(selectedDay));
                    },
                    // Styling
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: GoogleFonts.poppins(
                        color: _textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon:
                          Icon(Icons.chevron_left, color: _textGrey),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: _textGrey,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: GoogleFonts.lato(color: _textWhite),
                      weekendTextStyle: GoogleFonts.lato(color: _textGrey),
                      outsideTextStyle: GoogleFonts.lato(color: Colors.white12),
                      // Today
                      todayDecoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: _neonPink, width: 2),
                      ),
                      todayTextStyle: GoogleFonts.lato(
                        color: _neonPink,
                        fontWeight: FontWeight.bold,
                      ),
                      // Selected
                      selectedDecoration: BoxDecoration(
                        color: _neonGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _neonGreen.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      selectedTextStyle: GoogleFonts.lato(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // 2. DAILY SUMMARY (Count & Cost)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        label: "Smoked",
                        value: "${state.logsForSelectedDate.length}",
                        color: _neonOrange,
                        icon: Icons.smoking_rooms,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        label: "Status",
                        value: state.logsForSelectedDate.isEmpty
                            ? "Clean"
                            : "Relapse",
                        color: state.logsForSelectedDate.isEmpty
                            ? _neonGreen
                            : _neonPink,
                        icon: state.logsForSelectedDate.isEmpty
                            ? Icons.check_circle
                            : Icons.warning,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // 3. LOGS LIST
              state.loading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : state.logsForSelectedDate.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, idx) {
                              final log = state.logsForSelectedDate[idx];
                              final displayIndex =
                                  state.logsForSelectedDate.length - idx;

                              return Container(
                                margin:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: _surfaceDark,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: _neonPink.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            "#$displayIndex",
                                            style: GoogleFonts.robotoMono(
                                              color: _neonPink,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          "Cigarette Logged",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(log.timestamp),
                                      style: GoogleFonts.robotoMono(
                                          color: _textGrey, fontSize: 16),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: state.logsForSelectedDate.length,
                          ),
                        ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            // --- FIX: FittedBox prevents wrapping ---
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.lato(fontSize: 14, color: _textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.spa, size: 60, color: Colors.red.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(
          "Smoke Free Day!",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "No cigarettes logged for this date.",
          style: GoogleFonts.lato(color: _textGrey, fontSize: 14),
        ),
      ],
    );
  }
}
