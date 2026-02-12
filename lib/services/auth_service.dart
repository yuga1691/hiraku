import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<User> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) {
      try {
        await existing.reload();
        final refreshed = _auth.currentUser;
        if (refreshed != null) {
          return refreshed;
        }
      } on FirebaseAuthException catch (e) {
        if (e.code != 'user-not-found' && e.code != 'user-disabled') {
          rethrow;
        }
        await _auth.signOut();
      }
    }
    final result = await _auth.signInAnonymously();
    return result.user!;
  }
}
