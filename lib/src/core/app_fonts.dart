import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  AppFonts._();

  static final displayFont =
      GoogleFonts.spaceGrotesk().fontFamily ?? 'Space Grotesk';
  static final bodyFont = GoogleFonts.notoSans().fontFamily ?? 'Noto Sans';

  // Commonly used text styles
  static final TextStyle heading = TextStyle(
    fontFamily: displayFont,
    fontWeight: FontWeight.bold,
    fontSize: 24,
  );

  static final TextStyle subHeading = TextStyle(
    fontFamily: displayFont,
    fontWeight: FontWeight.w600,
    fontSize: 18,
  );

  static final TextStyle body = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
  );

  static final TextStyle small = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
  );
}
