import 'package:flutter/material.dart';

class AppColors {
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  // Background
  static Color background(BuildContext context) => 
      isDark(context) ? const Color(0xFF050816) : const Color(0xFFF8FAFC);
  
  // AI Card (Layer 2)
  static Color aiCard(BuildContext context) => 
      isDark(context) ? const Color(0xFF0F172A) : Colors.white;
  
  // Nested Card (Layer 3)
  static Color nestedCard(BuildContext context) => 
      isDark(context) ? const Color(0xFF020617) : const Color(0xFFF1F5F9);

  // Primary Action Color
  static const primary = Color(0xFF2563EB);

  // Text
  static Color textPrimary(BuildContext context) => 
      isDark(context) ? Colors.white : const Color(0xFF0F172A);
  
  static Color textSecondary(BuildContext context) => 
      isDark(context) ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

  // Borders
  static Color border(BuildContext context) => 
      isDark(context) ? const Color(0x1AFFFFFF) : const Color(0x1A0F172A);

  // Semantic
  static const urgent = Color(0xFFEF4444);
  static const completed = Color(0xFF22C55E);
  static const statHours = Color(0xFFF59E0B);
}
