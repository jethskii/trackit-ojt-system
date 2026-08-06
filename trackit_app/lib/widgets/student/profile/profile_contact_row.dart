import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class ProfileContactRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback? onTap;

  const ProfileContactRow({
    super.key,
    required this.name,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.background,
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryMaroon,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact "not assigned yet" row matching [ProfileContactRow]'s sizing,
/// shown in place of it when the department hasn't assigned this contact.
class MissingContactRow extends StatelessWidget {
  final String message;

  const MissingContactRow({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.chipGrayBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_off_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
