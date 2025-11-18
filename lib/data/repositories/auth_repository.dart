import 'package:quitsmoking/data/models/user_model.dart';

class SignInResult {
  final UserModel user;
  final bool isNewUser;
  SignInResult({required this.user, required this.isNewUser});
}

abstract class AuthRepository {
  Future<SignInResult?> signInWithGoogle();
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<bool> isUserExists(String uid);
  Future<void> saveUser(UserModel user, {bool markOnboarded = false});
}
