import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:acadia/l10n/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_durations.dart';
import '../../components/app_button.dart';
import '../../widgets/auth/auth_background_container.dart';

class OnboardingWelcomeScreen extends ConsumerStatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  ConsumerState<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends ConsumerState<OnboardingWelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onNext() {
    if (_currentPage < 3) {
      Haptics.vibrate(HapticsType.medium);
      _pageController.nextPage(
        duration: AppDurations.normal,
        curve: Curves.easeInOut,
      );
    } else {
      Haptics.vibrate(HapticsType.success);
      _complete();
    }
  }

  void _onSkip() {
    Haptics.vibrate(HapticsType.light);
    _complete();
  }

  void _complete() {
    ref.read(onboardingProvider.notifier).completeOnboarding();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final pages = [
      _OnboardingData(
        title: l10n?.onboardingTitle1 ?? '',
        description: l10n?.onboardingDesc1 ?? '',
        image: 'assets/onboarding/study.json',
      ),
      _OnboardingData(
        title: l10n?.onboardingTitle2 ?? '',
        description: l10n?.onboardingDesc2 ?? '',
        image: 'assets/onboarding/tasks.json',
      ),
      _OnboardingData(
        title: l10n?.onboardingTitle3 ?? '',
        description: l10n?.onboardingDesc3 ?? '',
        image: 'assets/onboarding/analytics.json',
      ),
      _OnboardingData(
        title: l10n?.onboardingTitle4 ?? '',
        description: l10n?.onboardingDesc4 ?? '',
        image: 'assets/onboarding/wellbeing.json',
      ),
    ];

    return Scaffold(
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Core Content (Bottom of stack gestures-wise if not fill)
              Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _currentPage = index),
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        return _OnboardingPageView(data: pages[index]);
                      },
                    ),
                  ),

                  // Bottom Section
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        // Page Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            pages.length,
                            (index) => AnimatedContainer(
                              duration: AppDurations.fast,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: _currentPage == index ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Next Button
                        AppButton(
                          onPressed: _onNext,
                          text: _currentPage == 3 
                              ? (l10n?.getStarted ?? '') 
                              : (l10n?.next ?? ''),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 2. Skip Button (Top of stack - receives gestures)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.lg,
                child: AppButton(
                  onPressed: _onSkip,
                  variant: AppButtonVariant.text,
                  text: l10n?.skip ?? '',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingData data;

  const _OnboardingPageView({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Illustration
          LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight =
                  MediaQuery.of(context).size.height * 0.4;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: AppDurations.slow,
                builder: (context, value, child) {
                  final parallaxOffset = 12.0 * (1 - value);
                  return Transform.translate(
                    offset: Offset(0, parallaxOffset),
                    child: SizedBox(
                      height: maxHeight,
                      child: child,
                    ),
                  );
                },
                child: Lottie.asset(
                  data.image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      AppIcon(
                    HeroIcons.sparkles,
                    size: 100,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ).animate(key: ValueKey(data.image))
                .fade(duration: AppDurations.slow)
                .slideY(begin: 0.1, curve: Curves.easeOut);
            },
          ),
          
          const Spacer(flex: 1),

          // Text Content
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ).animate(key: ValueKey(data.title))
                  .fade(duration: AppDurations.normal)
                  .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),
                
                const SizedBox(height: AppSpacing.lg),
                
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    height: 1.5,
                  ),
                ).animate(key: ValueKey(data.description))
                  .fade(delay: 100.ms, duration: AppDurations.normal),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final String image;

  _OnboardingData({
    required this.title,
    required this.description,
    required this.image,
  });
}
