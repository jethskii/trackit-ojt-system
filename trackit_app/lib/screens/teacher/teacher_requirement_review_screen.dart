import 'package:flutter/material.dart';
import '../../models/ojt_requirement_doc.dart';
import '../../models/ojt_requirement_phase.dart';
import '../../models/teacher_custom_requirement_submission.dart';
import '../../models/teacher_requirement_phase.dart';
import '../../models/teacher_requirement_student_summary.dart';
import '../../services/teacher_requirements_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/back_nav_header.dart';
import '../../widgets/common/skeleton_list_tile.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/teacher/requirement_progress_donut.dart';
import '../../widgets/teacher/teacher_requirement_doc_review_tile.dart';

/// Per-student requirements review: Progress Summary donut + a
/// stage-locked Official Requirements checklist, and a separate
/// Additional Requirements tab for instructor-created ones. Approving or
/// requesting a re-upload writes a real decision and notifies the
/// student -- there's no fabricated "AI recommendation"; the reviewer's
/// own note (remarks) is the real substitute the instructor types in.
class TeacherRequirementReviewScreen extends StatefulWidget {
  final int studentId;
  final TeacherRequirementsService service;

  const TeacherRequirementReviewScreen({
    super.key,
    required this.studentId,
    required this.service,
  });

  @override
  State<TeacherRequirementReviewScreen> createState() =>
      _TeacherRequirementReviewScreenState();
}

class _TeacherRequirementReviewScreenState
    extends State<TeacherRequirementReviewScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  TeacherStudentRequirements? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await widget.service.getStudentRequirements(widget.studentId);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  RequirementProgressSummary _bucketOf(List<RequirementDocStatus> statuses) {
    var completed = 0, needsReview = 0, pending = 0;
    for (final status in statuses) {
      if (status == RequirementDocStatus.approved) {
        completed++;
      } else if (status == RequirementDocStatus.submitted) {
        needsReview++;
      } else {
        pending++;
      }
    }
    return RequirementProgressSummary(completed: completed, needsReview: needsReview, pending: pending);
  }

  Future<void> _reviewOfficial(String submissionId, bool approve, {String? remarks}) async {
    await widget.service.reviewSubmission(submissionId: submissionId, approve: approve, remarks: remarks);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(approve ? 'Document approved.' : 'Re-upload requested.')),
    );
  }

  Future<void> _reviewCustom(String submissionId, bool approve, {String? remarks}) async {
    await widget.service.reviewCustomSubmission(submissionId: submissionId, approve: approve, remarks: remarks);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(approve ? 'Document approved.' : 'Re-upload requested.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Requirements Review'),
          Expanded(
            child: _loading || data == null
                ? const SkeletonList()
                : Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: AppColors.primaryMaroon,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: AppColors.textSecondary,
                            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            tabs: const [
                              Tab(text: 'Official Requirements'),
                              Tab(text: 'Additional Requirements'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _OfficialTab(
                                phases: data.phases,
                                summary: _bucketOf(
                                  data.phases.expand((p) => p.documents).map((d) => d.status).toList(),
                                ),
                                onDecision: _reviewOfficial,
                              ),
                              _AdditionalTab(
                                requirements: data.customRequirements,
                                summary: _bucketOf(
                                  data.customRequirements.map((c) => c.status).toList(),
                                ),
                                onDecision: _reviewCustom,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}

class _OfficialTab extends StatelessWidget {
  final List<TeacherRequirementPhase> phases;
  final RequirementProgressSummary summary;
  final Future<void> Function(String submissionId, bool approve, {String? remarks}) onDecision;

  const _OfficialTab({required this.phases, required this.summary, required this.onDecision});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        RequirementProgressDonut(summary: summary),
        const SizedBox(height: 20),
        const Text(
          'Requirements Checklist',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Stages unlock in order once every document in the previous stage is submitted.',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        for (final phase in phases) _PhaseSection(phase: phase, onDecision: onDecision),
      ],
    );
  }
}

class _PhaseSection extends StatelessWidget {
  final TeacherRequirementPhase phase;
  final Future<void> Function(String submissionId, bool approve, {String? remarks}) onDecision;

  const _PhaseSection({required this.phase, required this.onDecision});

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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          enabled: !isLocked,
          initiallyExpanded: phase.status == PhaseStatus.inProgress,
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: AppColors.primaryMaroon, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: isLocked
                ? const Icon(Icons.lock, color: Colors.white, size: 14)
                : Text(
                    '${phase.order}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
          ),
          title: Text(
            phase.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
          ),
          subtitle: Text(
            phase.description,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          trailing: Opacity(
            opacity: isLocked ? 0.6 : 1,
            child: StatusBadge(kind: _statusKind),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  for (final document in phase.documents)
                    TeacherRequirementDocReviewTile(
                      name: document.name,
                      description: document.description,
                      status: document.status,
                      uploadedFileName: document.uploadedFileName,
                      uploadedFileUrl: document.uploadedFileUrl,
                      remarks: document.remarks,
                      canReview: document.canReview,
                      onDecision: (approve, {remarks}) =>
                          onDecision(document.submissionId!, approve, remarks: remarks),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdditionalTab extends StatelessWidget {
  final List<TeacherCustomRequirementSubmission> requirements;
  final RequirementProgressSummary summary;
  final Future<void> Function(String submissionId, bool approve, {String? remarks}) onDecision;

  const _AdditionalTab({required this.requirements, required this.summary, required this.onDecision});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        RequirementProgressDonut(summary: summary),
        const SizedBox(height: 20),
        const Text(
          'Additional Requirements',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (requirements.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No additional requirements posted for this student\'s section yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          )
        else
          for (final requirement in requirements)
            TeacherRequirementDocReviewTile(
              name: requirement.name,
              description: requirement.description,
              status: requirement.status,
              uploadedFileName: requirement.uploadedFileName,
              uploadedFileUrl: requirement.uploadedFileUrl,
              remarks: requirement.remarks,
              canReview: requirement.canReview,
              onDecision: (approve, {remarks}) =>
                  onDecision(requirement.submissionId!, approve, remarks: remarks),
            ),
      ],
    );
  }
}
