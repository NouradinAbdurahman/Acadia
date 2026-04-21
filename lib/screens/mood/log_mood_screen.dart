import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

import '../../components/app_button.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/auth/auth_background_container.dart';

class LogMoodScreen extends ConsumerStatefulWidget {
  const LogMoodScreen({super.key, this.source = 'manual'});

  final String source;

  @override
  ConsumerState<LogMoodScreen> createState() => _LogMoodScreenState();
}

class _LogMoodScreenState extends ConsumerState<LogMoodScreen> {
  final TextEditingController _noteController = TextEditingController();
  final Set<String> _selectedFactors = <String>{};

  late PageController _pageController;
  int _moodLevel = 3;
  double _stressLevel = 5;
  double _energyLevel = 5;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.source == 'session') {
      final logs = ref.read(moodLogsProvider).valueOrNull ?? const [];
      if (logs.isNotEmpty) {
        final last = logs.first;
        _moodLevel = last.moodLevel;
        _stressLevel = last.stressLevel.toDouble().clamp(1.0, 10.0);
        _energyLevel = (last.energyLevel ?? 5).toDouble().clamp(1.0, 10.0);
      }
    }
    _pageController = PageController(
      initialPage: _moodLevel - 1,
      viewportFraction: 0.4,
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveMood() async {
    HapticFeedback.mediumImpact();
    
    final l10n = AppLocalizations.of(context)!;
    final previous = ref.read(moodLogsProvider).valueOrNull?.firstOrNull;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(moodActionsProvider).saveMoodLog(
            moodLevel: _moodLevel,
            stressLevel: _stressLevel.round(),
            energyLevel: _energyLevel.round(),
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            factors: _selectedFactors.toList(),
            source: widget.source,
          );

      if (!mounted) return;
      final messages = [
        l10n.moodSavedPositive1,
        l10n.moodSavedPositive2,
        l10n.moodSavedPositive3,
        l10n.moodSavedPositive4,
      ];
      final random = DateTime.now().millisecond % messages.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messages[random]),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.smartInsightUpdated),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (widget.source == 'session' && previous != null) {
        final deltaMood = _moodLevel - previous.moodLevel;
        final deltaStress = _stressLevel.round() - previous.stressLevel;
        final loopMessage = deltaMood > 0
            ? l10n.postSessionMoodImproved
            : (deltaStress > 1
                ? l10n.postSessionStressIncreased
                : l10n.postSessionFeedbackLogged);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loopMessage),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.moodSaveFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _emojiForMood(int level) {
    switch (level) {
      case 1: return '😞';
      case 2: return '🙁';
      case 3: return '😐';
      case 4: return '🙂';
      default: return '😄';
    }
  }

  Color _getMoodColor(int level, ThemeData theme) {
    switch (level) {
      case 1: return const Color(0xFFE53935); // Awful (clean red)
      case 2: return const Color(0xFFFF7043); // Bad (soft orange)
      case 3: return const Color(0xFFFFC107); // Neutral (amber)
      case 4: return const Color(0xFF66BB6A); // Good (soft green)
      case 5: return const Color(0xFF2ECC71); // Great (balanced green)
      default: return theme.colorScheme.primary;
    }
  }

  String _nameForMood(int level, AppLocalizations l10n) {
    switch (level) {
      case 1: return l10n.moodNameAwful;
      case 2: return l10n.moodNameBad;
      case 3: return l10n.moodNameNeutral;
      case 4: return l10n.moodNameGood;
      default: return l10n.moodNameGreat;
    }
  }

  Widget _buildMoodSelector(ThemeData theme, AppLocalizations l10n) {
    final activeMoodColor = _getMoodColor(_moodLevel, theme);

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: 5,
            onPageChanged: (index) {
              HapticFeedback.lightImpact();
              setState(() => _moodLevel = index + 1);
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.5)).clamp(0.7, 1.0);
                  } else {
                    value = (_moodLevel - 1) == index ? 1.0 : 0.7;
                  }
                  
                  final isSelected = _moodLevel == (index + 1);
                  final moodValue = index + 1;
                  final itemColor = _getMoodColor(moodValue, theme);

                  return Center(
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 12),
                      child: Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value.clamp(0.4, 1.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.98, end: 1.02),
                                duration: const Duration(milliseconds: 1200),
                                curve: Curves.easeInOut,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: isSelected ? scale : 1.0,
                                    child: child,
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  width: isSelected ? 90 : 70,
                                  height: isSelected ? 90 : 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.04),
                                    gradient: isSelected
                                        ? RadialGradient(
                                            colors: [
                                              itemColor.withValues(alpha: 0.25),
                                              itemColor.withValues(alpha: 0.12),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.2, 0.5, 1.0],
                                          )
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: itemColor.withValues(alpha: 0.25),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _emojiForMood(moodValue),
                                    style: TextStyle(fontSize: isSelected ? 42 : 32),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: isSelected ? 30 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [itemColor, itemColor.withValues(alpha: 0.6)],
                                        )
                                      : null,
                                  color: isSelected ? null : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            l10n.imFeelingMood(_nameForMood(_moodLevel, l10n)),
            key: ValueKey<int>(_moodLevel),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: activeMoodColor,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required Color activeColor,
    required ThemeData theme,
    required AppLocalizations l10n,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              value.round().toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: activeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 12,
            activeTrackColor: activeColor,
            inactiveTrackColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            thumbColor: Colors.white,
            overlayColor: activeColor.withValues(alpha: 0.2),
            valueIndicatorTextStyle: const TextStyle(color: Colors.white),
          ),
          child: Row(
            children: [
              Text(
                l10n.low,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: Slider(
                  min: 1,
                  max: 10,
                  value: value,
                  divisions: 9,
                  onChangeEnd: (_) => HapticFeedback.lightImpact(),
                  onChanged: onChanged,
                ),
              ),
              Text(
                l10n.high,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFactors(ThemeData theme, List<(String, String, IconData)> factors, Color moodColor) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: factors.map((entry) {
        final key = entry.$1;
        final label = entry.$2;
        final icon = entry.$3;
        final isSelected = _selectedFactors.contains(key);
        
        return _FactorChip(
          label: label,
          icon: icon,
          isSelected: isSelected,
          moodColor: moodColor,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedFactors.remove(key);
              } else {
                _selectedFactors.add(key);
              }
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final factors = <(String, String, IconData)>[
      ('sleep', l10n.moodFactorSleep, Icons.bedtime),
      ('workload', l10n.moodFactorWorkload, Icons.work_outline),
      ('health', l10n.moodFactorHealth, Icons.favorite_border),
      ('motivation', l10n.moodFactorMotivation, Icons.flash_on),
      ('social', l10n.moodFactorSocial, Icons.people_outline),
      ('exams', l10n.moodFactorExams, Icons.school),
    ];
    final activeMoodColor = _getMoodColor(_moodLevel, theme);

    // Dynamic Save Text
    final defaultSave = l10n.saveMood;
    final dynamicSaveText = l10n.saveMoodDots(_nameForMood(_moodLevel, l10n), _stressLevel.round().toString());

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const AppIcon(HeroIcons.arrowLeft),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.logMoodTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            widget.source == 'session'
                                ? l10n.moodAfterSessionPrompt
                                : l10n.moodManualPrompt,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Form Sections
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      // SECTION 1: MOOD SELECTOR
                      _buildMoodSelector(theme, l10n),

                      const SizedBox(height: 48),

                      // SECTION 2: STRESS & ENERGY
                      _buildSlider(
                        label: l10n.stressLevel,
                        value: _stressLevel,
                        onChanged: (v) => setState(() => _stressLevel = v),
                        activeColor: Colors.deepOrangeAccent,
                        theme: theme,
                        l10n: l10n,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSlider(
                        label: l10n.energyLevel,
                        value: _energyLevel,
                        onChanged: (v) => setState(() => _energyLevel = v),
                        activeColor: Colors.tealAccent.shade400,
                        theme: theme,
                        l10n: l10n,
                      ),

                      const SizedBox(height: 48),

                      // SECTION 3: FACTORS
                      Text(
                        l10n.moodFactors,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildFactors(theme, factors, activeMoodColor),

                      const SizedBox(height: 48),

                      // SECTION 4: NOTES
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: TextField(
                          controller: _noteController,
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: l10n.addQuickNoteOptional,
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 64),
                    ],
                  ),
                ),
              ),

              // SECTION 5: SAVE BUTTON (Sticky Bottom)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppButton(
                  text: _isSaving ? defaultSave : dynamicSaveText,
                  onPressed: _isSaving ? null : _saveMood,
                  isLoading: _isSaving,
                  isFullWidth: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactorChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color moodColor;
  final VoidCallback onTap;

  const _FactorChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.moodColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 160),
        tween: Tween(begin: isSelected ? 0.95 : 1.0, end: 1.0),
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isSelected ? moodColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: isSelected ? moodColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: moodColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check, size: 14, color: moodColor),
                const SizedBox(width: 4),
              ],
              Icon(icon, size: 16, color: isSelected ? moodColor : Colors.white70),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? moodColor : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

