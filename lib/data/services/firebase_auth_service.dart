import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:quitsmoking/data/models/user_model.dart';
import 'package:quitsmoking/data/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final GoogleSignIn googleSignIn;
  final fb.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  static const usersCollection = 'users';

  FirebaseAuthRepository({
    required this.googleSignIn,
    required this.firebaseAuth,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<SignInResult?> signInWithGoogle() async {
    try {
      final account = await googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final userCred = await firebaseAuth.signInWithCredential(credential);
      final fbUser = userCred.user;
      if (fbUser == null) return null;

      final docRef = firestore.collection(usersCollection).doc(fbUser.uid);
      final doc = await docRef.get();

      final userModel = UserModel.fromFirebaseUser(fbUser);

      if (!doc.exists) {
        // new user: create doc with createdAt and isFullyOnboarded false
        await docRef.set(userModel.toCreationMap());
        return SignInResult(user: userModel, isNewUser: true);
      } else {
        // existing user: merge update fields (keep createdAt)
        await docRef.set(userModel.toUpdateMap(), SetOptions(merge: true));
        final map = doc.data()!;
        final merged = UserModel.fromMap({...map, 'uid': fbUser.uid});
        return SignInResult(user: merged, isNewUser: false);
      }
    } catch (e) {
      // bubble up: caller should handle network / firebase errors
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
    await googleSignIn.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final fbUser = firebaseAuth.currentUser;
    if (fbUser == null) return null;

    try {
      final doc = await firestore
          .collection(usersCollection)
          .doc(fbUser.uid)
          .get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists && doc.data() != null) {
        final map = doc.data()!;
        return UserModel.fromMap({...map, 'uid': fbUser.uid});
      } else {
        return UserModel.fromFirebaseUser(fbUser);
      }
    } catch (e) {
      // If firestore unreachable, fallback to fb user fields
      return UserModel.fromFirebaseUser(fbUser);
    }
  }

  @override
  Future<bool> isUserExists(String uid) async {
    try {
      final doc = await firestore.collection(usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> saveUser(UserModel user, {bool markOnboarded = false}) async {
    final docRef = firestore.collection(usersCollection).doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set(user.toCreationMap());
    } else {
      await docRef.set(
        user.toUpdateMap(markOnboarded: markOnboarded),
        SetOptions(merge: true),
      );
    }
  }
}
