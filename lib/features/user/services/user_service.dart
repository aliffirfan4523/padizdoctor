import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createUser({
    required User firebaseUser,
    required String fullName,
    String? profilePicture,
    bool isAdmin = false,
  }) async {
    final userRef = _db.collection('users').doc(firebaseUser.uid);
    final activityRef = userRef.collection('activitySummary').doc("stats");

    final batch = _db.batch();

    // Users table
    batch.set(userRef, {
      'fullName': fullName,
      'email': firebaseUser.email,
      'profilePicture': profilePicture ??
          'https://thumbs.dreamstime.com/b/default-profile-picture-avatar-photo-placeholder-vector-illustration-default-profile-picture-avatar-photo-placeholder-vector-189495158.jpg',
      'isAdmin': isAdmin,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ActivitySummary table
    batch.set(activityRef, {
      'userId': firebaseUser.uid,
      'totalSubmissions': 0,
      'totalProcessingTime': 0.0,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> updateUserInfo(String fullName, String email) async {
    // Implementation to update user profile
    User? user = _auth.currentUser;

    if (user != null) {
      String uid = user.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fullName': fullName,
      });
    }
  }

  Future<void> updateEmailAddress(String newEmail) async {
    final User? user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null) {
        await user.verifyBeforeUpdateEmail(newEmail);
        // print('Verification email sent to new address. Email will update after verification.');
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (e.code == 'requires-recent-login') {
        // Prompt the user to re-authenticate
      }
    } catch (e) {
      // An error occurred
    }
  }

  Future<String> updatePassword(String oldPassword, String newPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    final AuthCredential credential = EmailAuthProvider.credential(
      email: user!.email!,
      password: oldPassword, // User's current password
    );

    try {
      await user.reauthenticateWithCredential(credential);
      // Re-authentication successful, now update the password
      await user.updatePassword(newPassword);
      return ("Password updated successfully!");
    } on FirebaseAuthException catch (e) {
      // Handle specific errors like 'wrong-password' or 'requires-recent-login'
      return ("Error: ${e.message}");
    }
  }

  Future<void> migrateUserActivitySummary() async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in usersSnapshot.docs) {
      String uid = userDoc.id;

      // 1. Get the sub-collection 'activitySummary' for this user
      var summarySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('activitySummary')
          .get();

      for (var oldDoc in summarySnapshot.docs) {
        // 2. Skip if it's already named 'stats'
        if (oldDoc.id == 'stats') continue;

        // 3. Copy data to the new 'stats' document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('activitySummary')
            .doc('stats')
            .set(oldDoc.data(), SetOptions(merge: true));

        // 4. Delete the old random ID document
        await oldDoc.reference.delete();
        // Migration log
      }
    }
    // Migration Complete
  }
}
