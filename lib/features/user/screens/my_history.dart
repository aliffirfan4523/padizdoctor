import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/core/widgets/Recent_Scans_List.dart';

import '../../../core/widgets/reusable_header.dart';

class MyHistory extends StatefulWidget {
  MyHistory({super.key, required this.currentUserId});
  final String currentUserId;
  @override
  State<MyHistory> createState() => _MyHistoryState();
}

class _MyHistoryState extends State<MyHistory> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text('My History',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // 2. Recent Scans List (Dynamic)
            buildHeader(title: "Recent Scans"),
            SizedBox(height: 20),
            RecentScansList(userId: widget.currentUserId, limit: 3)
          ],
        ),
      ),
    );
  }
}
