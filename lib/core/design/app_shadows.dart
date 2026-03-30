import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 10),
    )
  ];

  static List<BoxShadow> get subtle => [
    BoxShadow(
      color: AppColors.shadowSoft,
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get primaryGlow => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
