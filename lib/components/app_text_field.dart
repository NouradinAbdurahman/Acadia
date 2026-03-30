import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../core/design/app_radius.dart';
import '../core/design/app_spacing.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../core/design/app_icons.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final HeroIcons? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: widget.controller,
      obscureText: _isObscured,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      maxLines: widget.maxLines,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: theme.textTheme.bodySmall,
        prefixIcon: widget.prefixIcon != null
            ? AppIcon(
                widget.prefixIcon!,
                color: theme.textTheme.bodySmall?.color,
                size: 20,
              )
            : null,
        suffixIcon: widget.obscureText 
            ? IconButton(
                icon: AppIcon(
                  _isObscured ? HeroIcons.eye : HeroIcons.eyeSlash,
                  color: theme.textTheme.bodySmall?.color,
                  size: 20,
                ),
                onPressed: () {
                  Haptics.vibrate(HapticsType.light);
                  setState(() => _isObscured = !_isObscured);
                },
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      ),
    );
  }
}
