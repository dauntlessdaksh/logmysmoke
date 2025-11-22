// lib/data/repositories/smoke_log_repository.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quitsmoking/data/models/smoke_log_model.dart';

class SmokeLogRepository {
  final FirebaseFirestore firestore;
  static const String usersCollection = 'users';
  static const String smokeLogsCollection = 'smoke_logs';

  SmokeLogRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  // Path: users/{uid}/smoke_logs
  CollectionReference<Map<String, dynamic>> _userSmokeLogsRef(String uid) {
    return firestore
        .collection(usersCollection)
        .doc(uid)
        .collection(smokeLogsCollection);
  }

  /// Stream smoke logs for a given user ordered by timestamp descending (newest first)
  Stream<List<SmokeLog>> streamLogsForUser(String uid) {
    final col = _userSmokeLogsRef(uid);

    // We order by timestamp descending. If timestamp is missing at creation time,
    // SmokeLog.fromDoc will fallback to DateTime.now() and the stream will update
    // once serverTimestamp is available (so UI may show a brief flicker).
    return col.orderBy('timestamp', descending: true).snapshots().map((snap) {
      return snap.docs.map((d) => SmokeLog.fromDoc(d)).toList();
    });
  }

  /// Add a smoke log for a user. Uses server timestamp.
  Future<String> addLog(String uid, {required double cost}) async {
    try {
      final col = _userSmokeLogsRef(uid);
      final ref = await col.add({
        'userId': uid,
        'cost': cost,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } on FirebaseException catch (e) {
      print('Firestore addLog error: $e');
      rethrow;
    }
  }

  /// Delete a specific log
  Future<void> deleteLog(String uid, String logId) async {
    try {
      await _userSmokeLogsRef(uid).doc(logId).delete();
    } catch (e) {
      print('deleteLog error: $e');
      rethrow;
    }
  }

  /// Get logs once (useful for non-stream reads)
  Future<List<SmokeLog>> getLogsOnce(String uid) async {
    final snap = await _userSmokeLogsRef(
      uid,
    ).orderBy('timestamp', descending: true).get();
    return snap.docs.map((d) => SmokeLog.fromDoc(d)).toList();
  }
}
