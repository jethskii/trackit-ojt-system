import 'package:flutter/material.dart';
import '../../models/admin_class.dart';
import '../../utils/app_colors.dart';

/// Shared by Class Management and the Overview dashboard -- both are
/// scoped to one academic year at a time and must never mix data across
/// years, so this is the single control that decides which year's data
/// is showing everywhere it appears.
class AcademicYearPicker extends StatelessWidget {
  final List<AdminAcademicYear> years;
  final String? selected;
  final ValueChanged<String> onSelected;

  /// Null hides "+ Add Academic Year" -- Overview is a read-only
  /// monitoring surface, not where a new academic year would normally
  /// get created (that's Class Management's Create Section flow).
  final VoidCallback? onAddNew;

  const AcademicYearPicker({
    super.key,
    required this.years,
    required this.selected,
    required this.onSelected,
    this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    final matches = years.where((y) => y.year == selected);
    final current = matches.isEmpty ? null : matches.first;
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == '__add__') {
          onAddNew?.call();
        } else {
          onSelected(value);
        }
      },
      itemBuilder: (context) => [
        for (final y in years)
          PopupMenuItem(
            value: y.year,
            child: Text(y.isCurrent ? '${y.year} (Active)' : y.year),
          ),
        if (onAddNew != null) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(value: '__add__', child: Text('+ Add Academic Year')),
        ],
      ],
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.chipGrayBg),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Academic Year: ',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              Text(
                selected ?? '--',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (current?.isCurrent ?? false)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successGreenBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successGreenText,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
