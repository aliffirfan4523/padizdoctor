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
    final activityRef = userRef.collection('activitySummary').doc();

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
      'avgDetectionTime': 0.0,
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
        'email': email,
      });
    }
  }
}
