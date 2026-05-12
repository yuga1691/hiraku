import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleSignInInitialization;

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

  Future<UserCredential> linkCurrentUserWithGoogle() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('ログイン中のユーザーがいません。');
    }
    if (isGoogleLinked(currentUser)) {
      throw FirebaseAuthException(
        code: 'provider-already-linked',
        message: 'Googleアカウントはすでに連携済みです。',
      );
    }

    await _initializeGoogleSignIn();
    if (!_googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError('この環境ではGoogleログインを開始できません。');
    }

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw StateError('Google認証トークンを取得できませんでした。');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await currentUser.linkWithCredential(credential);
    await result.user?.reload();
    return result;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _initializeGoogleSignIn();
    if (!_googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError('この環境ではGoogleログインを開始できません。');
    }

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw StateError('Google認証トークンを取得できませんでした。');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    await result.user?.reload();
    return result;
  }

  bool isGoogleLinked(User? user) {
    return user?.providerData.any(
          (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
        ) ??
        false;
  }

  Future<void> _initializeGoogleSignIn() {
    return _googleSignInInitialization ??= _googleSignIn.initialize();
  }
}
