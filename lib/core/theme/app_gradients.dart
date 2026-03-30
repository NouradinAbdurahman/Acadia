import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  static const darkBackground = RadialGradient(
    center: Alignment.center,
    radius: 1.5,
    colors: [
      AppColors.backgroundDarkStart,
      AppColors.backgroundDarkEnd,
    ],
  );

  static const lightBackground = RadialGradient(
    center: Alignment.center,
    radius: 1.5,
    colors: [
      Color(0xFFF1F5F9),
      AppColors.backgroundLight,
    ],
  );

  static const primaryAction = LinearGradient(
    colors: [
      AppColors.primaryDark,
      AppColors.primary,
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const primaryActionDisabled = LinearGradient(
    colors: [
      Colors.grey,
      Colors.grey,
    ],
  );
}
