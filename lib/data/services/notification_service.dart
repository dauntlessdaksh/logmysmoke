import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const usersCollection = 'users';

  /// Call once on app start (after Firebase.initializeApp).
  static Future<void> init() async {
    // request permission on ios/android
    await _requestPermission();
    String? debugToken = await _messaging.getToken();
    debugPrint('--- DEBUG: MY TOKEN IS: $debugToken ---');
    // handle background message (optional)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // optionally listen to token refresh
    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('FCM Token refreshed: $token');
      // Note: Ideally, update firestore here if you have access to the current User ID
    });
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
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
        // 'notificationsEnabled': true, // Optional: Ensure this is true if you want to auto-enable
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      debugPrint('Token saved to Firestore for user: $uid');
    } catch (e) {
      debugPrint('Error saving token to Firestore: $e');
    }
  }

  /// Remove token from user doc (used when turning notifications off or signout)
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

  /// Add or update the notificationsEnabled flag in user doc
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

  /// Background message handler required for FCM
  // --- FIXED: Added pragma for Android Background Isolation ---
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage msg,
  ) async {
    // Keep minimal; Cloud Functions does sending. This handler can be used for analytics.
    debugPrint('Handling a background message: ${msg.messageId}');
  }
}
