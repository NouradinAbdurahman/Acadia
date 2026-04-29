import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/bottom_nav_provider.dart';
import '../../core/design/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import '../tasks/tasks_list_screen.dart';
import '../study/study_screen.dart';
import '../analytics/analytics_screen.dart';
import '../profile/profile_screen.dart';
import '../../providers/study_sessions_provider.dart';
import 'liquid_glass_navbar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavProvider);
    final timerState = ref.watch(studyTimerProvider);
    final isSessionActive = timerState.isRunning || timerState.isPaused;
    final theme = Theme.of(context);
    // Match AuthBackground gradient end color — transparent scaffold composites badly with
    // BackdropFilter on tab switches and can flash; solid base avoids that.
    final shellBaseBg = theme.brightness == Brightness.dark
        ? AppColors.backgroundDarkEnd
        : AppColors.backgroundLight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      primary: false,
      backgroundColor:
          isSessionActive ? theme.scaffoldBackgroundColor : shellBaseBg,
      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: const [
              HomeScreen(),
              TasksListScreen(),
              StudyScreen(),
              AnalyticsScreen(),
              ProfileScreen(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: RepaintBoundary(
                  child: LiquidGlassNavbar(
                    selectedIndex: selectedIndex,
                    onSelectedIndex: (index) {
                      ref.read(bottomNavProvider.notifier).state = index;
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
