import 'package:flutter/material.dart';
import '../../../models/ojt_requirement_phase.dart';
import '../../../utils/app_colors.dart';
import '../../common/status_badge.dart';

class PhaseCard extends StatelessWidget {
  final OjtRequirementPhase phase;
  final VoidCallback onTap;

  const PhaseCard({super.key, required this.phase, required this.onTap});

  StatusKind get _statusKind {
    switch (phase.status) {
      case PhaseStatus.locked:
        return StatusKind.locked;
      case PhaseStatus.inProgress:
        return StatusKind.inProgress;
      case PhaseStatus.completed:
        return StatusKind.completed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = phase.status == PhaseStatus.locked;

    return Opacity(
      opacity: isLocked ? 0.6 : 1,
      child: Material(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryMaroon,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isLocked
                      ? const Icon(Icons.lock, color: Colors.white, size: 16)
                      : Text(
                          '${phase.order}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                              phase.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          StatusBadge(kind: _statusKind),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phase.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLocked)
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
