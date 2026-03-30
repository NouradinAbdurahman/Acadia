import 'package:flutter/material.dart';
import '../../core/theme/app_gradients.dart';

class AuthBackgroundContainer extends StatelessWidget {
  final Widget child;

  const AuthBackgroundContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.darkBackground : AppGradients.lightBackground,
      ),
      child: child,
    );
  }
}
