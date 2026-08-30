import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/auth_config.dart';

class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    final serverClientId = kGoogleSignInWebClientId.trim();
    await GoogleSignIn.instance.initialize(
      serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
    );
    _initialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await initialize();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw GoogleAuthException(
        'Google Sign-In is not supported on this device.',
      );
    }

    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw GoogleAuthException(_configurationMessage());
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleAuthException('Sign-in canceled.', canceled: true);
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw GoogleAuthException(_configurationMessage());
      }
      throw GoogleAuthException(
        e.description ?? 'Google Sign-In failed (${e.code.name}).',
      );
    } on FirebaseAuthException catch (e) {
      throw GoogleAuthException(
        e.message ?? 'Firebase authentication failed.',
      );
    }
  }

  Future<void> ensureUserProfile(UserCredential userCred) async {
    if (userCred.additionalUserInfo?.isNewUser != true) return;

    await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
      'name': userCred.user!.displayName ?? 'OnAlert User',
      'email': userCred.user!.email,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _configurationMessage() {
    return 'Google Sign-In is not configured in Firebase.\n\n'
        '1. Firebase Console → Authentication → Sign-in method → enable Google\n'
        '2. Project settings → Your Android app → add SHA-1:\n'
        '   $kAndroidDebugSha1\n'
        '3. Re-download google-services.json into android/app/\n'
        '4. Rebuild the app\n\n'
        'Or set kGoogleSignInWebClientId in lib/config/auth_config.dart';
  }
}

class GoogleAuthException implements Exception {
  final String message;
  final bool canceled;

  GoogleAuthException(this.message, {this.canceled = false});

  @override
  String toString() => message;
}
