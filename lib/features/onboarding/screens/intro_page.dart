import 'package:flutter/material.dart';
import 'package:padizdoctor/core/utils/colors_utils.dart';
import 'package:padizdoctor/features/settings/services/settings_controller.dart';

import 'package:shared_preferences/shared_preferences.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key, required this.controller});

  final SettingsController controller;

  Future<void> _finishIntro(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isFirstTime", false);
    Navigator.pushReplacementNamed(
      context,
      "/login",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            "https://firebasestorage.googleapis.com/v0/b/padizdoctor-fyp-6820b.firebasestorage.app/o/images%2Fintrogif.gif?alt=media&token=1da9d9a9-63ac-441a-929f-184678aa7f19",
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                "assets/images/intropage.png",
                fit: BoxFit.cover,
              );
            },
          ),

          // Dark overlay for readability
          Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),

          // Content with semi-transparent box
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color:
                    Colors.black.withValues(alpha: 0.4), // semi-transparent box
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Image.asset(
                    "assets/images/logo2.png", // replace with your logo path
                    height: 150, // adjust as needed
                    width: 150,
                  ),
                  const SizedBox(height: 20),

                  // Headline
                  Text(
                    "Welcome to PadizDoctor",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle / promotional text
                  Text(
                    "Quickly identify paddy leaf diseases with our smart detection system, ensuring healthier crops, higher productivity, and more efficient farm management.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 20),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hexStringToColor("#388E3C"),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        _finishIntro(context);
                      },
                      child: const Text(
                        "Get Started",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
