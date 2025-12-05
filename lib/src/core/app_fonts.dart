import 'package:flutter/material.dart';

class AppFonts {
  AppFonts._();

  static const String poppins = 'Poppins';

  // Commonly used text styles
  static const TextStyle heading = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.bold,
    fontSize: 24,
  );

  static const TextStyle subHeading = TextStyle(
    fontFamily: poppins,
    fontWeight: FontWeight.w600,
    fontSize: 18,
  );

  static const TextStyle body = TextStyle(
    fontFamily: poppins,
    fontSize: 14,
  );

  static const TextStyle small = TextStyle(
    fontFamily: poppins,
    fontSize: 12,
  );
}
