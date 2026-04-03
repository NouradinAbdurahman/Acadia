import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import 'dart:ui';
import '../../../core/design/app_spacing.dart';
import '../../../providers/study_sessions_provider.dart';
import '../../../l10n/app_localizations.dart';

class StudySessionDialogs {
  static void showStopConfirm(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: anim1,
              curve: Curves.easeOutBack,
            ),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const HeroIcon(
                                HeroIcons.exclamationTriangle,
                                color: Color(0xFFEF4444),
                                size: 36,
                                style: HeroIconStyle.solid,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.stopSessionTitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.stopSessionConfirm,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: _DialogButton(
                                    label: l10n.cancel,
                                    isOutline: true,
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _DialogButton(
                                    label: l10n.stop,
                                    isDanger: true,
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ref.read(studyTimerProvider.notifier).stop();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDanger;
  final bool isOutline;

  const _DialogButton({
    required this.label,
    required this.onPressed,
    this.isDanger = false,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isOutline 
            ? theme.colorScheme.onSurface.withValues(alpha: 0.05) 
            : isDanger 
              ? const Color(0xFFEF4444) 
              : theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          border: isOutline 
            ? Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1), width: 1.5) 
            : null,
          boxShadow: !isOutline ? [
            BoxShadow(
              color: (isDanger ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isOutline 
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.8) 
                  : theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
