import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryPurpleDark = Color(0xFF2d1b4e);
  static const Color primaryPurple = Color(0xFF5d5787);
  static const Color primaryPurpleLight = Color(0xFF7d6fa7);

  // Accent Colors
  static const Color accentRed = Color(0xFFb3001b);
  static const Color accentRedDark = Color(0xFF8f0015);
  static const Color accentPeach = Color(0xFFf4d6cc);
  static const Color accentCream = Color(0xFFffd3b6);
  static const Color accentLavender = Color(0xFFc8b6e2);
  static const Color accentMint = Color(0xFFa8d5ba);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurpleDark, primaryPurple, primaryPurpleLight],
  );

  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accentRedDark, accentRed],
  );

  // MiniPlayer gradient
  static const Color purpleGradientStart = Color(0xFF6B21A8);
  static const Color purpleGradientEnd = Color(0xFF9333EA);
}
