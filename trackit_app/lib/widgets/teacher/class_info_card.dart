import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/instructor_class.dart';
import '../../utils/app_colors.dart';

class ClassInfoCard extends StatelessWidget {
  final InstructorClass instructorClass;

  const ClassInfoCard({super.key, required this.instructorClass});

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: instructorClass.activationCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activation code copied.')),
    );
  }

  void _copyInvitation(BuildContext context) {
    // No hosted web link / app deep-link exists to join a class directly,
    // so this copies a shareable instruction message instead of a URL
    // that wouldn't actually go anywhere.
    final message =
        'Join our TRACKIT class (${instructorClass.program} - '
        '${instructorClass.section}, ${instructorClass.academicYear}): '
        'open the TRACKIT app, tap Register, and enter activation code '
        '${instructorClass.activationCode}.';
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitation message copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups, size: 16, color: AppColors.primaryMaroon),
              SizedBox(width: 6),
              Text(
                'CLASS INFORMATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryMaroon,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoField(
                  icon: Icons.school_outlined,
                  label: 'Program & Section',
                  value: '${instructorClass.program} - ${instructorClass.section}',
                ),
              ),
              Expanded(
                child: _InfoField(
                  icon: Icons.event_outlined,
                  label: 'Academic Year',
                  value: instructorClass.academicYear,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Class Activation Code',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    instructorClass.activationCode,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _copyCode(context),
                icon: const Icon(Icons.copy, size: 15),
                label: const Text('Copy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryMaroon,
                  side: const BorderSide(color: AppColors.primaryMaroon),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copyInvitation(context),
              icon: const Icon(Icons.link, size: 16),
              label: const Text('Copy Invitation Link'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryMaroon,
                side: const BorderSide(color: AppColors.primaryMaroon),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoField({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
