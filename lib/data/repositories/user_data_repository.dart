// lib/data/repositories/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quitsmoking/data/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore firestore;
  static const users = 'users';

  UserRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserModel?> getUserById(String uid) async {
    final doc = await firestore.collection(users).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(Map<String, dynamic>.from(doc.data()!));
  }

  Future<void> updateUserFields(String uid, Map<String, dynamic> map) async {
    await firestore
        .collection(users)
        .doc(uid)
        .set(map, SetOptions(merge: true));
  }
}
