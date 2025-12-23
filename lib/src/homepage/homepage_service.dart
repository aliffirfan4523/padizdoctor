import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomepageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetches the current user's ID and their Firestore data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      // 1. Get the current logged-in user
      User? user = _auth.currentUser;

      if (user != null) {
        String uid = user.uid;

        // 2. Reference the specific document using the UID
        DocumentSnapshot doc = await _db.collection('users').doc(uid).get();

        if (doc.exists) {
          // 3. Return the data as a Map
          return doc.data() as Map<String, dynamic>;
        } else {
          print("No Firestore document found for this UID.");
          return null;
        }
      } else {
        print("No user is currently logged in.");
        return null;
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> loadData() async {
    HomepageService db = HomepageService();
    var userData = await db.getCurrentUserData();

    if (userData != null) {
      return userData;
    } else {
      print("Failed to load user data.");
      return null;
    }
  }
}

// In your widget's State class, wrap setState with a mounted check:
// Example:
// if (mounted) {
//   setState(() {
//     // update state here
//   });
// }
