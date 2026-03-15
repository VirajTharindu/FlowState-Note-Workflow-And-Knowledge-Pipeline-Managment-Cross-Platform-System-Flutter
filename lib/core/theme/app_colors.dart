import 'package:flutter/material.dart';

class AppColors {
  // Primary palette (Gradient Base)
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFF0EA5E9); // Sky Blue
  static const Color accent = Color(0xFFFB7185); // Rose

  // Dark Mode Colors
  static const Color background = Color(0xFF1E1B4B); // Deep Indigo
  static const Color surface = Color(0xFF312E81); // Lighter Indigo Surface
  static const Color card = Color(0xFF7F1D1D); // Dark Red (Base)

  // Text Colors (Optimized for pink/indigo gradients)
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFFCE7F3); // Light Pink Tint
  static const Color textMuted = Color(0xFFA5B4FC); // Indigo 300

  // Status Colors (Restored for compatibility)
  static const Color error = Color(0xFFE11D48); // Rose / Red
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6); // Blue

  // Gradients (The core of the new theme)
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFB7185), Color(0xFF1E1B4B)], // Rose to Deep Indigo
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFBCFE8), Color(0xFFFDA4AF)], // Light Pink to Rose
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4ADE80), Color(0xFF10B981)], // Light Green to Emerald
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF0EA5E9)], // Indigo to Sky Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color glassSurface = Colors.white.withOpacity(0.08);
  static Color glassBorder = Colors.white.withOpacity(0.15);
}
