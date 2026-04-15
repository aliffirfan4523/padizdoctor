import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});

  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  bool _loading = true;
  String _route = "/intro";

  @override
  void initState() {
    super.initState();
    decideRoute();
  }

  Future<void> decideRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool("isFirstTime") ?? true;

    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      if (isFirstTime) {
        _route = "/intro";
      } else if (user != null) {
        _route = "/home";
      } else {
        _route = "/login";
      }

      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, _route);
    });

    return const SizedBox.shrink();
  }
}
