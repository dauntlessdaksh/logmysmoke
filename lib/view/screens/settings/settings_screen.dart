import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quitsmoking/data/services/notification_service.dart';
import 'package:quitsmoking/viewmodel/auth/auth_state.dart';
import 'package:quitsmoking/viewmodel/auth/auth_bloc.dart';
import 'package:quitsmoking/viewmodel/auth/auth_event.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  String? _uid;

  // --- LOCAL COLOR PALETTE ---
  final Color _bgBlack = const Color(0xFF000000);
  final Color _surfaceDark = const Color(0xFF151517);
  final Color _textWhite = const Color(0xFFFFFFFF);
  final Color _textGrey = const Color(0xFF8D8D8D);
  final Color _neonPink = const Color(0xFFFF4FA6);
  final Color _dangerRed = const Color(0xFFFF453A);

  @override
  void initState() {
    super.initState();
    final st = context.read<AuthBloc>().state;
    if (st is AuthAuthenticated) {
      _uid = st.user.uid;
      _notificationsEnabled = st.user.notificationsEnabled ?? false;
    }
  }

  Future<void> _toggle(bool value) async {
    if (_uid == null) return;
    setState(() => _notificationsEnabled = value);
    await NotificationService.setNotificationsEnabled(_uid!, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            context.go('/home');
          },
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            color: _textWhite,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // --- SECTION: PREFERENCES ---
            Text(
              "PREFERENCES",
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _textGrey,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),

            // Notification Tile
            Container(
              decoration: BoxDecoration(
                color: _surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                value: _notificationsEnabled,
                onChanged: _toggle,
                activeColor: _neonPink, // Neon accent
                activeTrackColor: _neonPink.withOpacity(0.3),
                inactiveThumbColor: _textGrey,
                inactiveTrackColor: Colors.black,
                title: Text(
                  'Notifications',
                  style: GoogleFonts.poppins(
                    color: _textWhite,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Daily motivation & reminders',
                  style: GoogleFonts.lato(color: _textGrey, fontSize: 12),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _neonPink.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: _neonPink,
                    size: 20,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- SECTION: ACCOUNT ---
            Text(
              "ACCOUNT",
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _textGrey,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),

            // Logout Button
            GestureDetector(
              onTap: () {
                context.read<AuthBloc>().add(SignOutRequested());
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: _surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _dangerRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _dangerRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: _dangerRed,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Log Out",
                      style: GoogleFonts.poppins(
                        color: _dangerRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: _dangerRed.withOpacity(0.5),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Version info
            Center(
              child: Text(
                "Version 1.0.0",
                style: GoogleFonts.lato(color: Colors.white12, fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
