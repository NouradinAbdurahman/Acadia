import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:heroicons/heroicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../components/app_glass_card.dart';
import '../../components/app_bottom_sheet_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    final appUser = ref.watch(currentAppUserProvider).asData?.value;
    final avatarUrl = appUser?.avatarUrl;
    final bottomNavClearance = MediaQuery.of(context).padding.bottom + 120;

    Future<void> uploadAvatar(File file) async {
      try {
        Haptics.vibrate(HapticsType.medium);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.saving),
              duration: const Duration(seconds: 1),
            ),
          );
        }

        final newUrl = await ref.read(avatarServiceProvider).uploadAvatar(file);
        PaintingBinding.instance.imageCache.evict(NetworkImage(newUrl));
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        ref.invalidate(currentAppUserProvider);
        await ref.read(currentAppUserProvider.future);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.avatarUpdated)));
        }
      } catch (e) {
        debugPrint("Upload error: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.avatarUploadFailed}: $e')),
          );
        }
      }
    }

    Future<void> handleAvatarTap() async {
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 80,
        );

        if (image == null) return;
        await uploadAvatar(File(image.path));
      } catch (e) {
        debugPrint("Error picking image: $e");
      }
    }

    Widget buildItem({
      required dynamic icon,
      required String title,
      Widget? trailing,
      Color? textColor,
      VoidCallback? onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              icon is HeroIcons
                  ? HeroIcon(icon, color: Colors.blueAccent, size: 22)
                  : Icon(icon as IconData, color: Colors.blueAccent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor ?? theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              trailing ??
                  HeroIcon(
                    HeroIcons.chevronRight,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 20,
                  ),
            ],
          ),
        ),
      );
    }

    Widget buildSection({
      required String title,
      required List<Widget> children,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          AppGlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 50,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // --- HEADER ---
                Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: handleAvatarTap,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blueAccent,
                                        Colors.blueAccent.withValues(
                                          alpha: 0.3,
                                        ),
                                        Colors.blueAccent.withValues(
                                          alpha: 0.1,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blueAccent.withValues(
                                          alpha: isDark ? 0.3 : 0.15,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 38,
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.05),
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : const AssetImage(
                                                'assets/images/default_avatar.png',
                                              )
                                              as ImageProvider,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: const HeroIcon(
                                      HeroIcons.camera,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appUser?.name ?? l10n.student,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fade(duration: 400.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOut),

                const SizedBox(height: 16),

                // --- ACADEMIC SECTION ---
                buildSection(
                  title: l10n.academicInformation,
                  children: [
                    buildItem(
                      icon: HeroIcons.identification,
                      title: l10n.editProfile,
                      onTap: () => context.push('/profile/edit'),
                    ),
                    buildItem(
                      icon: HeroIcons.academicCap,
                      title: l10n.manageCourses,
                      onTap: () => context.push('/courses'),
                    ),
                  ],
                ),

                // --- PREFERENCES SECTION ---
                buildSection(
                  title: l10n.studyPreferences,
                  children: [
                    buildItem(
                      icon: HeroIcons.adjustmentsHorizontal,
                      title: l10n.studyPreferences,
                      onTap: () => context.push('/profile/study-preferences'),
                    ),
                    buildItem(
                      icon: HeroIcons.language,
                      title: l10n.language,
                      trailing: GestureDetector(
                        onTap: () async {
                          final selected =
                              await showAppBottomSheetPicker<String>(
                                context: context,
                                theme: theme,
                                icon: HeroIcons.language,
                                sheetTitle: l10n.language,
                                options: [
                                  AppPickerOption(
                                    value: 'en',
                                    title: l10n.languageEnglish,
                                  ),
                                  AppPickerOption(
                                    value: 'tr',
                                    title: l10n.languageTurkish,
                                  ),
                                ],
                                selectedValue: locale.languageCode,
                              );
                          if (selected == null) return;
                          ref
                              .read(localeProvider.notifier)
                              .setLocale(Locale(selected));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                locale.languageCode == 'tr'
                                    ? l10n.languageTurkish
                                    : l10n.languageEnglish,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              HeroIcon(
                                HeroIcons.chevronDown,
                                size: 16,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    buildItem(
                      icon: HeroIcons.moon,
                      title: l10n.theme,
                      trailing: Switch.adaptive(
                        value: themeMode == ThemeMode.dark,
                        activeThumbColor: Colors.blueAccent,
                        onChanged: (val) {
                          ref
                              .read(themeProvider.notifier)
                              .setTheme(val ? ThemeMode.dark : ThemeMode.light);
                        },
                      ),
                    ),
                  ],
                ),

                // --- ACCOUNT SECTION ---
                buildSection(
                  title: l10n.accountSettings,
                  children: [
                    buildItem(
                      icon: HeroIcons.shieldCheck,
                      title: l10n.privacyPolicy,
                      onTap: () {},
                    ),
                    buildItem(
                      icon: HeroIcons.lockClosed,
                      title: l10n.changePassword,
                      onTap: () => context.push('/profile/change-password'),
                    ),
                    buildItem(
                      icon: HeroIcons.arrowRightOnRectangle,
                      title: l10n.logout,
                      textColor: Colors.redAccent,
                      onTap: () => ref.read(authRepositoryProvider).logout(),
                    ),
                  ],
                ),

                SizedBox(height: bottomNavClearance),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
