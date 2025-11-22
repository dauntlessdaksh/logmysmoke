import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- 1. Add this import
import 'package:firebase_core/firebase_core.dart';
import 'package:quitsmoking/view/my_app.dart';
import 'firebase_options.dart';
import 'package:quitsmoking/data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 2. LOCK ORIENTATION TO PORTRAIT UP ---
  // This prevents the "Bottom Overflowed" error on small screens in landscape mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Notifications
  await NotificationService.init();

  runApp(const MyApp());
}
