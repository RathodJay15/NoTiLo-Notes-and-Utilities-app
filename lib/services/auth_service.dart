import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _rememberMeKey = 'remember_me';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      //print('signIn success uid=${cred.user?.uid}');
      return cred;
    } catch (e, st) {
      //print('signIn error: $e\n$st');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> setRememberMe(bool value) async {
    await _secureStorage.write(
      key: _rememberMeKey,
      value: value ? 'true' : 'false',
    );
    //print('remember_me set to $value');
  }

  Future<bool> getRememberMe() async {
    final val = await _secureStorage.read(key: _rememberMeKey);
    return val == 'true';
  }

  Future<void> enforceRememberMeOnStartup() async {
    final remember = await getRememberMe();
    final currentUser = _auth.currentUser;
    if (!remember && currentUser != null) {
      try {
        // Check if user signed in recently (within 3 seconds) to avoid race condition
        final idTokenResult = await currentUser.getIdTokenResult(true);
        final authTime = idTokenResult.claims?['auth_time'];
        if (authTime != null) {
          final authTimeSeconds = int.tryParse(authTime.toString()) ?? 0;
          final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          if (nowSeconds - authTimeSeconds <= 3) {
            //print('User recently signed in, skipping auto sign-out');
            return;
          }
        }
      } catch (e) {
        //print('Error checking auth time: $e');
      }
      //print('Signing out user (remember_me is false)');
      await signOut();
    }
  }
}
