import 'package:flutter/material.dart';
import '../../../models/company_details.dart';
import '../../../models/ojt_requirement_phase.dart';
import '../../../services/ojt_requirements_service.dart';
import '../../../services/student_profile_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/info_reminder_card.dart';
import '../../../widgets/common/skeleton_list_tile.dart';
import '../../../widgets/student/documents/phase_card.dart';
import 'confirm_company_details_screen.dart';
import 'phase_requirements_screen.dart';

class StartupRequirementsScreen extends StatefulWidget {
  final OjtRequirementsService service;
  final StudentProfileService profileService;

  const StartupRequirementsScreen({
    super.key,
    required this.service,
    required this.profileService,
  });

  @override
  State<StartupRequirementsScreen> createState() =>
      _StartupRequirementsScreenState();
}

class _StartupRequirementsScreenState
    extends State<StartupRequirementsScreen> {
  List<OjtRequirementPhase> _phases = [];
  CompanyDetails? _companyDetails;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final phases = await widget.service.getPhases();
    final profile = await widget.profileService.getProfile();
    if (!mounted) return;
    setState(() {
      _phases = phases;
      _companyDetails = profile.company;
      _loading = false;
    });
  }

  Future<void> _openPhase(OjtRequirementPhase phase) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhaseRequirementsScreen(
          phaseId: phase.id,
          service: widget.service,
        ),
      ),
    );
    _load();
  }

  Future<void> _openConfirmCompanyDetails() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => ConfirmCompanyDetailsScreen(
          service: widget.profileService,
          existingDetails: _companyDetails,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: AppColors.successGreenText,
        ),
      );
    }
  }

  double get _progress {
    if (_phases.isEmpty) return 0;
    final completed = _phases
        .where((p) => p.status == PhaseStatus.completed)
        .length;
    return completed / _phases.length;
  }

  bool get _allCompleted =>
      _phases.isNotEmpty &&
      _phases.every((p) => p.status == PhaseStatus.completed);

  Future<void> _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Startup Requirements'),
          Expanded(
            child: _loading
                ? const SkeletonList()
                : RefreshIndicator(
                    color: AppColors.primaryMaroon,
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _OverallProgressCard(progress: _progress),
                            const SizedBox(height: 16),
                            const InfoReminderCard(
                              message:
                                  'Complete each phase in order. Some phases '
                                  'will unlock automatically once '
                                  'requirements are met.',
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Requirements',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (final phase in _phases) ...[
                              PhaseCard(
                                phase: phase,
                                onTap: () => _openPhase(phase),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 8),
                            const Text(
                              'Details Confirmation',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _allCompleted
                                ? _FinalizationCard(
                                    companyDetails: _companyDetails,
                                    onTap: _openConfirmCompanyDetails,
                                  )
                                : const _PendingConfirmationCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  final double progress;

  const _OverallProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Progress',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryMaroon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: AppColors.background,
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.primaryMaroon,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingConfirmationCard extends StatelessWidget {
  const _PendingConfirmationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryMaroon,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Complete all pre requisite requirements and start your OJT Journey!',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _FinalizationCard extends StatelessWidget {
  final CompanyDetails? companyDetails;
  final VoidCallback onTap;

  const _FinalizationCard({required this.companyDetails, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = companyDetails != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.successGreenBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            isConfirmed ? Icons.verified : Icons.check_circle,
            color: AppColors.successGreenText,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            'Confirm Company Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.successGreenText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isConfirmed
                ? 'Company details confirmed for ${companyDetails!.name}. '
                    'You can update them anytime.'
                : 'Requirements completed. Confirm your OJT company details '
                    'to finish setting up your account.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.successGreenText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreenText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isConfirmed ? 'Edit Details' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
