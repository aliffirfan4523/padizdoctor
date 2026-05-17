import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:padizdoctor/features/user/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  final userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription? _googleAuthSub;

  /// Call ONCE during app startup
  Future<void> initializeGoogleSignIn() async {
    await GoogleSignIn.instance.initialize(
      clientId:
          '533916619628-k0fb6j78l27434b84m79o0nq308f2uji.apps.googleusercontent.com',
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
          await userService.createUser(
            firebaseUser: user,
            fullName: user.displayName ?? '',
            profilePicture: user.photoURL ?? '',
          );
        } else {
          // Optional: Update lastActive even if user exists
          await docRef.update({'lastActive': DateTime.now()});
        }
      }

      return userCredential;
    } catch (e) {
      // Google Sign-In Error
      return null;
    }
  }

  /// Whether the current user signed in with Google only (no email/password linked)
  bool get isGoogleOnly {
    final user = _auth.currentUser;
    if (user == null) return false;
    final providerIds = user.providerData.map((p) => p.providerId).toSet();
    return providerIds.contains('google.com') && !providerIds.contains('password');
  }

  /// Link an email/password credential to the current Google-only user
  /// so they can also sign in with email + password.
  Future<String> linkEmailPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user signed in.';
      if (user.email == null) return 'No email associated with this account.';

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.linkWithCredential(credential);
      return 'success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        return 'Email/password is already linked to this account.';
      } else if (e.code == 'weak-password') {
        return 'Password is too weak. Use at least 6 characters.';
      }
      return e.message ?? 'Failed to link account.';
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  /// Send a password-reset email via Firebase Auth.
  Future<String> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return 'success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No account found with that email.';
      }
      return e.message ?? 'Failed to send reset email.';
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hasSeenCameraInstructions_${user.uid}');
    }

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
