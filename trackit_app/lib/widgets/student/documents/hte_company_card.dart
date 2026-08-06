import 'package:flutter/material.dart';
import '../../../models/hte_company.dart';
import '../../../utils/app_colors.dart';

class HteCompanyCard extends StatelessWidget {
  final HteCompany company;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const HteCompanyCard({
    super.key,
    required this.company,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.background,
                child: Text(
                  company.name.isNotEmpty
                      ? company.name.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryMaroon,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            company.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Semantics(
                          label: isFavorite
                              ? 'Remove ${company.name} from favorites'
                              : 'Add ${company.name} to favorites',
                          button: true,
                          child: InkWell(
                            onTap: onToggleFavorite,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: isFavorite
                                    ? AppColors.statRedIcon
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company.industry,
                      style: const TextStyle(
                        color: AppColors.accentOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            company.address,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statBlueBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${company.availableSlots} Slots Available',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statBlueIcon,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
