import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription? _googleAuthSub;

  /// Call ONCE during app startup
  Future<void> initializeGoogleSignIn() async {
    await GoogleSignIn.instance.initialize(
      clientId:
          '533916619628-k0fb6j78l27434b84m79o0nq308f2uji.apps.googleusercontent.com',
    );

    _googleAuthSub = GoogleSignIn.instance.authenticationEvents.listen(
      (event) async {
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn():
            await _signInToFirebase(event.user);
            break;

          case GoogleSignInAuthenticationEventSignOut():
            await FirebaseAuth.instance.signOut();
            break;
        }
      },
    );
  }

  /// Trigger Google UI
  Future<void> signInWithGoogle() async {
    await GoogleSignIn.instance.authenticate(
      scopeHint: ['email'],
    );
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  Future<void> _signInToFirebase(GoogleSignInAccount user) async {
    final googleAuth = await user.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    await _auth.signInWithCredential(credential);
  }

  void dispose() {
    _googleAuthSub?.cancel();
  }
}
