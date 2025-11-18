import 'package:shared_preferences/shared_preferences.dart';
import 'package:quitsmoking/data/repositories/user_data_repository.dart';

class SharedPrefsRepository implements UserDataRepository {
  final SharedPreferences prefs;

  SharedPrefsRepository({required this.prefs});

  static const String keyIsFirstTime = 'isFirstTime';
  static const String keyIsLoggedIn = 'isLoggedIn';

  @override
  Future<bool> isFirstTime() async {
    // default true until you flip it off after onboarding
    return prefs.getBool(keyIsFirstTime) ?? true;
    // e.g., call setFirstTime(false) after onboarding completes
  }

  @override
  Future<void> setFirstTime(bool value) async {
    await prefs.setBool(keyIsFirstTime, value);
  }

  @override
  Future<void> setLoggedIn(bool value) async {
    await prefs.setBool(keyIsLoggedIn, value);
  }

  @override
  Future<bool> isLoggedIn() async {
    return prefs.getBool(keyIsLoggedIn) ?? false;
  }
}
