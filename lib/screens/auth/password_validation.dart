import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

String? validatePasswordForSignup(String? value, AppLocalizations? l10n) {
  if (value == null || value.length < 8) {
    return l10n?.passwordTooShort ?? '';
  }
  return null;
}

String? validateConfirmPasswordForSignup(
  String? value,
  String password,
  AppLocalizations? l10n,
) {
  if (value != password) {
    return l10n?.passwordsDoNotMatch ?? '';
  }
  return null;
}

String passwordStrengthLabel(String password, AppLocalizations? l10n) {
  if (password.length >= 8) {
    return l10n?.passwordStrong ?? '';
  }
  if (password.length >= 5) {
    return l10n?.passwordFair ?? '';
  }
  return l10n?.passwordWeak ?? '';
}

Color passwordStrengthColor(ThemeData theme, String password) {
  if (password.length >= 8) {
    return theme.colorScheme.primary;
  }
  if (password.length >= 5) {
    return Colors.orange;
  }
  return theme.colorScheme.error;
}
