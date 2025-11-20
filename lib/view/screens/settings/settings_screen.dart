// lib/view/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // fix path if needed
import 'package:quitsmoking/data/services/notification_service.dart';
import 'package:quitsmoking/viewmodel/auth/auth_state.dart';
import 'package:quitsmoking/viewmodel/auth/auth_bloc.dart';
import 'package:quitsmoking/viewmodel/auth/auth_event.dart'; // Import the file containing SignOutRequested
import 'package:quitsmoking/core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  String? _uid;

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
    // If toggled on, token will be saved by NotificationService
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // navigate to home explicitly to avoid route stack issues
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              value: _notificationsEnabled,
              onChanged: _toggle,
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive daily motivations and reminders.'),
              activeColor: AppColors.neonGreen,
            ),
            // other settings...
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                // logout button
                context.read<AuthBloc>().add(SignOutRequested());
                // AuthBloc will navigate due to router redirect
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
