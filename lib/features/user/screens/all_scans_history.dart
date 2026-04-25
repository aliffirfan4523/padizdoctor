import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/core/widgets/Recent_Scans_List.dart';

class AllScansHistoryScreen extends StatelessWidget {
  const AllScansHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Scans'),
        centerTitle: true,
      ),
      body: userId == null
          ? const Center(child: Text("Please log in to view history."))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: RecentScansList(userId: userId), // No limit
            ),
    );
  }
}
