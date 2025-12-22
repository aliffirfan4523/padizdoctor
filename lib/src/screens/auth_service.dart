import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      // 1. Perform Authentication
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // Note: Ensure GoogleSignIn().signIn() is used to get the account
        final GoogleSignInAccount googleUser =
            await GoogleSignIn.instance.authenticate(); // User canceled

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }

      // 2. Firestore Logic
      User? user = userCredential.user;

      if (user != null) {
        final docRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        final doc = await docRef.get();

        if (!doc.exists) {
          await docRef.set({
            'email': user.email,
            // Use Google's name if the controller isn't available
            'fullName': user.displayName ?? '',
            'isAdmin': false,
            'lastActive': DateTime.now(),
            'phone': user.phoneNumber ?? '',
            'profilePicture': user.photoURL ?? '',
          });
        } else {
          // Optional: Update lastActive even if user exists
          await docRef.update({'lastActive': DateTime.now()});
        }
      }

      return userCredential;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
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
