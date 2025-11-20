import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quitsmoking/view/my_app.dart';
import 'firebase_options.dart';
// Make sure this import path matches where your file actually is
import 'package:quitsmoking/data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- FIXED: Initialize Notifications on App Start ---
  await NotificationService.init();

  runApp(const MyApp());
}
