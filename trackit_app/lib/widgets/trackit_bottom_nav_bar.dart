import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TrackitNavItem {
  final IconData icon;
  final String label;

  const TrackitNavItem({required this.icon, required this.label});
}

const List<TrackitNavItem> trackitNavItems = [
  TrackitNavItem(icon: Icons.home_rounded, label: 'Home'),
  TrackitNavItem(icon: Icons.groups_rounded, label: 'Students'),
  TrackitNavItem(icon: Icons.description_rounded, label: 'Document'),
  TrackitNavItem(icon: Icons.campaign_rounded, label: 'Notification'),
  TrackitNavItem(icon: Icons.person_rounded, label: 'Profile'),
];

/// Bottom navigation bar shared across the teacher module's five tabs.
class TrackitBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const TrackitBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < trackitNavItems.length; i++)
              _NavButton(
                item: trackitNavItems[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final TrackitNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.orange : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: selected ? AppColors.orange : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
