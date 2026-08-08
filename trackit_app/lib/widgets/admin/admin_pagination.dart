import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Shared numbered pager used across Admin's tables/lists (Class
/// Management's student table, Announcements feed). Shows a window of
/// page buttons centered on the current page so this doesn't overflow on
/// a list with many pages.
class AdminPagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onChanged;

  const AdminPagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const windowSize = 5;
    var start = (page - windowSize ~/ 2).clamp(0, (totalPages - windowSize).clamp(0, totalPages));
    var end = (start + windowSize).clamp(0, totalPages);
    start = (end - windowSize).clamp(0, totalPages);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PageButton(
          icon: Icons.chevron_left,
          onTap: page > 0 ? () => onChanged(page - 1) : null,
        ),
        for (var p = start; p < end; p++)
          _PageButton(
            label: '${p + 1}',
            selected: p == page,
            onTap: () => onChanged(p),
          ),
        _PageButton(
          icon: Icons.chevron_right,
          onTap: page < totalPages - 1 ? () => onChanged(page + 1) : null,
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const _PageButton({this.label, this.icon, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: selected ? AppColors.primaryMaroon : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? AppColors.primaryMaroon : AppColors.chipGrayBg,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: icon != null
                ? Icon(
                    icon,
                    size: 16,
                    color: onTap == null
                        ? AppColors.textSecondary.withValues(alpha: 0.4)
                        : AppColors.textSecondary,
                  )
                : Text(
                    label!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
