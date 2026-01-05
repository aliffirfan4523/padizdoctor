import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/src/app/app_scaffold.dart';
import 'package:padizdoctor/src/auth/auth_service.dart';

import '../homepage/homepage_service.dart';
import '../settings/settings_controller.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key, required this.controller});
  final SettingsController controller;
  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  final service = HomepageService();
  final auth = AuthService.instance;
  final FirebaseAuth googleAuth = FirebaseAuth.instance;
  var selectedIndex = 0;
  StreamSubscription<DocumentSnapshot>? _userSub;
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user!.uid;

    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;

      setState(() {
        _userData = {
          ...doc.data()!,
          'user_id': doc.id,
        };
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      controller: widget.controller,
      user: _userData!,
    );
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}
