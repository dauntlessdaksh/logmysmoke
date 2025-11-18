abstract class UserDataRepository {
  Future<bool> isFirstTime();
  Future<void> setFirstTime(bool value);

  Future<void> setLoggedIn(bool value);
  Future<bool> isLoggedIn();
}



