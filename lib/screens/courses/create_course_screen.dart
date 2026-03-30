import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_radius.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/course_provider.dart';
import '../../models/course.dart';
import '../../providers/app_providers.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../providers/semester_provider.dart';
import '../../core/design/app_icons.dart';
import '../../components/app_button.dart';
import '../../l10n/app_localizations.dart';

class CreateCourseScreen extends ConsumerStatefulWidget {
  final Course? courseToEdit;
  const CreateCourseScreen({super.key, this.courseToEdit});

  @override
  ConsumerState<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends ConsumerState<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late int _semester;
  int? _credits;
  int? _ects;
  late String _selectedColor;
  bool _isLoading = false;
  String? _selectedSemesterId;

  final List<String> _availableColors = [
    '#3B82F6', // Blue
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#10B981', // Green
    '#F59E0B', // Orange
    '#EF4444', // Red
    '#06B6D4', // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.courseToEdit?.courseName);
    _codeController = TextEditingController(text: widget.courseToEdit?.courseCode);
    _semester = widget.courseToEdit?.semester ?? 1;
    _selectedSemesterId = widget.courseToEdit?.semesterId;
    _credits = widget.courseToEdit?.credits;
    _ects = widget.courseToEdit?.ects;
    _selectedColor = widget.courseToEdit?.color ?? _availableColors[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    final l10n = AppLocalizations.of(context)!;
    if (_credits == null || _credits! <= 0) {
      _showError(l10n.pleaseSelectCourse); // Or better: "Credits is required"
      return;
    }
    if (_ects == null || _ects! <= 0) {
      _showError("ECTS is required");
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final course = Course(
        id: widget.courseToEdit?.id ?? '',
        userId: user.id,
        courseName: _nameController.text.trim(),
        courseCode: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
        semester: _semester,
        semesterId: _selectedSemesterId,
        credits: _credits!,
        ects: _ects!,
        color: _selectedColor,
        createdAt: widget.courseToEdit?.createdAt ?? DateTime.now(),
      );

      if (widget.courseToEdit == null) {
        await ref.read(courseProvider.notifier).addCourse(course);
      } else {
        await ref.read(courseProvider.notifier).updateCourse(course);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.networkError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
     );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseToEdit == null ? l10n.addCourse : l10n.editCourse),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSectionHeader(l10n.overview),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _nameController,
                    label: l10n.taskTitle, // or add courseName key
                    hint: l10n.courseNameHint,
                    icon: HeroIcons.bookOpen,
                    validator: (val) => val == null || val.isEmpty ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _codeController,
                    label: l10n.courseCode,
                    hint: l10n.courseCodeHint,
                    icon: HeroIcons.hashtag,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionHeader(l10n.details),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberPicker(
                          label: l10n.currentSemesterNumber,
                          value: _semester,
                          onChanged: (val) => setState(() => _semester = val),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildNumberPicker(
                          label: l10n.creditsLabel,
                          value: _credits,
                          onChanged: (val) => setState(() => _credits = val),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildNumberPicker(
                          label: "ECTS",
                          value: _ects,
                          onChanged: (val) => setState(() => _ects = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSemesterDropdown(l10n),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionHeader(l10n.courseColor),
                  const SizedBox(height: AppSpacing.md),
                  _buildColorPicker(),
                  const SizedBox(height: AppSpacing.xl * 2),
                  _buildSaveButton(l10n),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    final isValid = _credits != null && _credits! > 0 && _ects != null && _ects! > 0;
    
    return AppButton(
      text: (widget.courseToEdit == null ? l10n.save : l10n.saveChanges),
      isLoading: _isLoading,
      onPressed: isValid ? () {
        Haptics.vibrate(HapticsType.light);
        _saveCourse();
      } : null,
      isFullWidth: true,
    );
  }

  Widget _buildSemesterDropdown(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final semestersAsync = ref.watch(semesterProvider);

    return semestersAsync.when(
      data: (semesters) {
        if (semesters.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.glassSurface : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark ? AppColors.glassBorder : theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedSemesterId,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              decoration: InputDecoration(
                labelText: l10n.selectSemester,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AppIcon(HeroIcons.calendar, color: theme.colorScheme.primary, size: 20),
                ),
                border: InputBorder.none,
              ),
              items: semesters.map((s) => DropdownMenuItem(
                value: s.id,
                child: Text(s.name, style: theme.textTheme.bodyLarge),
              )).toList(),
              onChanged: (val) => setState(() => _selectedSemesterId = val),
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.2,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required HeroIcons icon,
    String? hint,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.glassBorder : theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: AppIcon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildNumberPicker({
    required String label,
    required int? value,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.glassBorder : theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactButton(
                icon: HeroIcons.minusCircle,
                onTap: (value ?? 0) > 1 ? () => onChanged(value! - 1) : null,
                enabled: (value ?? 0) > 1,
                theme: theme,
              ),
              Text(
                value?.toString() ?? "-",
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              _buildCompactButton(
                icon: HeroIcons.plusCircle,
                onTap: () => onChanged((value ?? 0) + 1),
                enabled: true,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButton({
    required HeroIcons icon,
    required VoidCallback? onTap,
    required bool enabled,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AppIcon(
          icon,
          size: 18,
          color: enabled ? theme.colorScheme.primary : theme.disabledColor,
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _availableColors.map((colorStr) {
        final color = Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
        final isSelected = _selectedColor == colorStr;

        return AnimatedPressable(
          onTap: () => setState(() => _selectedColor = colorStr),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? const AppIcon(HeroIcons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
