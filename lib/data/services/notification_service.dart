import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Added this
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Initialize Local Notifications Plugin
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const usersCollection = 'users';

  // 2. Define the High Importance Channel (For Android 8.0+)
  // This ensures the notification makes sound and pops up
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.max, // Critical for "Heads Up" display
    playSound: true,
  );

  /// Call once on app start (after Firebase.initializeApp).
  static Future<void> init() async {
    // --- A. Setup Local Notifications (Android/iOS) ---
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Uses your App Icon

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);

    // Create the channel on the device (Android)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // --- B. Request Permissions ---
    await _requestPermission();

    // Debug print token
    String? debugToken = await _messaging.getToken();
    debugPrint('--- DEBUG: MY TOKEN IS: $debugToken ---');

    // --- C. Handle Background Messages ---
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // --- D. HANDLE FOREGROUND MESSAGES (The New Logic) ---
    // This listens for messages while the app is OPEN and shows a local banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If notification data exists, show it visually using LocalNotifications
      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('FCM Token refreshed: $token');
    });
  }

  static Future<void> _requestPermission() async {
    // 1. Firebase Permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 2. Local Notification Permission (Android 13+)
    // This is required for newer Android phones to show the pop-up
    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    debugPrint('FCM permission: ${settings.authorizationStatus}');
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM getToken => $token');
      return token;
    } catch (e) {
      debugPrint('FCM getToken error: $e');
      return null;
    }
  }

  /// Save token to user's document (users/{uid}.fcmToken)
  static Future<void> saveTokenToFirestore(String uid) async {
    final token = await getToken();
    if (token == null) return;

    try {
      await _firestore.collection(usersCollection).doc(uid).set({
        'fcmToken': token,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      debugPrint('Token saved to Firestore for user: $uid');
    } catch (e) {
      debugPrint('Error saving token to Firestore: $e');
    }
  }

  /// Remove token from user doc
  static Future<void> removeTokenFromFirestore(String uid) async {
    try {
      final docRef = _firestore.collection(usersCollection).doc(uid);
      await docRef.set({
        'fcmToken': FieldValue.delete(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('removeTokenFromFirestore error: $e');
    }
  }

  /// Add or update the notificationsEnabled flag
  static Future<void> setNotificationsEnabled(String uid, bool enabled) async {
    await _firestore.collection(usersCollection).doc(uid).set({
      'notificationsEnabled': enabled,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    if (enabled) {
      await saveTokenToFirestore(uid);
    } else {
      await removeTokenFromFirestore(uid);
    }
  }

  /// Background message handler
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage msg,
  ) async {
    debugPrint('Handling a background message: ${msg.messageId}');
  }
}
