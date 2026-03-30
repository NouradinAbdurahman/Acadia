import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_radius.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/semester_provider.dart';
import '../../models/semester.dart';
import '../../providers/app_providers.dart';
import '../../widgets/auth/auth_background_container.dart';
import '../../core/design/app_icons.dart';
import '../../components/app_button.dart';
import '../../l10n/app_localizations.dart';

class CreateSemesterScreen extends ConsumerStatefulWidget {
  final Semester? semesterToEdit;
  const CreateSemesterScreen({super.key, this.semesterToEdit});

  @override
  ConsumerState<CreateSemesterScreen> createState() => _CreateSemesterScreenState();
}

class _CreateSemesterScreenState extends ConsumerState<CreateSemesterScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.semesterToEdit?.name);
    _startDate = widget.semesterToEdit?.startDate;
    _endDate = widget.semesterToEdit?.endDate;
    _isCurrent = widget.semesterToEdit?.isCurrent ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSemester() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final semester = Semester(
        id: widget.semesterToEdit?.id ?? '',
        userId: user.id,
        name: _nameController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        isCurrent: _isCurrent,
        createdAt: widget.semesterToEdit?.createdAt ?? DateTime.now(),
      );

      if (widget.semesterToEdit == null) {
        await ref.read(semesterProvider.notifier).addSemester(semester);
      } else {
        await ref.read(semesterProvider.notifier).updateSemester(semester);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.semesterToEdit == null ? l10n.addSemester : l10n.editSemester),
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
                  _buildSectionHeader(l10n.semester),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _nameController,
                    label: l10n.semesterName,
                    hint: l10n.semesterNameHint,
                    icon: HeroIcons.calendar,
                    validator: (val) => val == null || val.isEmpty ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDatePicker(
                    label: l10n.startDate,
                    value: _startDate,
                    onChanged: (val) => setState(() => _startDate = val),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDatePicker(
                    label: l10n.endDate,
                    value: _endDate,
                    onChanged: (val) => setState(() => _endDate = val),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SwitchListTile(
                    title: Text(l10n.currentSemesterNumber),
                    subtitle: Text(l10n.setAsActive),
                    value: _isCurrent,
                    onChanged: (val) => setState(() => _isCurrent = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.xl * 2),
                  AppButton(
                    onPressed: _isLoading ? null : _saveSemester,
                    text: _isLoading ? l10n.saving : (widget.semesterToEdit == null ? l10n.createSemester : l10n.updateSemester),
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  surface: isDark ? const Color(0xFF1E293B) : Colors.white,
                  onSurface: isDark ? Colors.white : Colors.black,
                ), dialogTheme: DialogThemeData(backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white),
              ),
              child: child!,
            );
          },
        );
        if (date != null) onChanged(date);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? AppColors.glassBorder : theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  value == null ? 'Select Date' : '${value.day}/${value.month}/${value.year}',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            AppIcon(HeroIcons.calendar, color: theme.colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
