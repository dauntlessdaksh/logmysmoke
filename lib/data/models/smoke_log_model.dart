// lib/data/models/smoke_log_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SmokeLog {
  final String id;
  final String userId;
  final double cost;
  final DateTime timestamp;

  SmokeLog({
    required this.id,
    required this.userId,
    required this.cost,
    required this.timestamp,
  });

  factory SmokeLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawTs = data['timestamp'];

    DateTime ts;
    if (rawTs == null) {
      ts = DateTime.now();
    } else if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return SmokeLog(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
      timestamp: ts,
    );
  }

  Map<String, dynamic> toCreationMap() {
    return <String, dynamic>{
      // set timestamp on server side via FieldValue.serverTimestamp() in repo
      'userId': userId,
      'cost': cost,
    };
  }
}
