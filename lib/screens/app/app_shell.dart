import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/bottom_nav_provider.dart';
import '../../core/design/app_spacing.dart';
import '../home/home_screen.dart';
import '../tasks/tasks_list_screen.dart';
import '../study/study_screen.dart';
import '../analytics/analytics_screen.dart';
import '../profile/profile_screen.dart';
import 'liquid_glass_navbar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Background will come from children
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
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: LiquidGlassNavbar(
                  selectedIndex: selectedIndex,
                  onSelectedIndex: (index) =>
                      ref.read(bottomNavProvider.notifier).state = index,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

