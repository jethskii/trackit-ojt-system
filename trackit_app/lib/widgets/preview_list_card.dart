import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Card used for the Announcements / Notifications previews on the Home
/// screen: shows the most recent item, or an empty state when there's none.
class PreviewListCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String? title;
  final String? subtitle;
  final String emptyLabel;
  final VoidCallback? onTap;

  const PreviewListCard({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.emptyLabel,
    this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = title != null;

    return InkWell(
      onTap: hasContent ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? emptyLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: hasContent ? FontWeight.w600 : FontWeight.w500,
                      color: hasContent ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (hasContent)
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
