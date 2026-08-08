import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Shared stub for sidebar sections not built out this round (Overview,
/// HTE Directory, Archive, Announcements, Profile). Mirrors the shape of
/// EmptyStateView but full-bleed, since these are whole panels rather than
/// a section within a screen.
class AdminPlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const AdminPlaceholderScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.cardWhite,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 32, color: AppColors.primaryMaroon),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coming soon.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
