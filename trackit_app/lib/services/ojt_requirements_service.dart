import '../models/ojt_requirement_doc.dart';
import '../models/ojt_requirement_phase.dart';

/// Repository-style interface for the Startup Requirements workflow.
///
/// NOTE: real admin approval requires the Admin module + backend, which
/// don't exist yet. Until then, a document counts as fulfilling its phase
/// once it's submitted (see [OjtRequirementPhase.isFulfilled]) instead of
/// waiting for a separate approval step.
abstract class OjtRequirementsService {
  Future<List<OjtRequirementPhase>> getPhases();

  Future<List<OjtRequirementPhase>> submitDocument({
    required String phaseId,
    required String documentId,
    required String fileName,
  });
}

class MockOjtRequirementsService implements OjtRequirementsService {
  late List<OjtRequirementPhase> _phases;

  MockOjtRequirementsService() {
    _phases = _buildInitialPhases();
    _recomputePhaseStatuses();
  }

  @override
  Future<List<OjtRequirementPhase>> getPhases() async {
    return List.unmodifiable(_phases);
  }

  @override
  Future<List<OjtRequirementPhase>> submitDocument({
    required String phaseId,
    required String documentId,
    required String fileName,
  }) async {
    _phases = _phases.map((phase) {
      if (phase.id != phaseId) return phase;
      final updatedDocs = phase.documents.map((doc) {
        if (doc.id != documentId) return doc;
        return doc.copyWith(
          status: RequirementDocStatus.submitted,
          uploadedFileName: fileName,
        );
      }).toList();
      return phase.copyWith(documents: updatedDocs);
    }).toList();

    _recomputePhaseStatuses();
    return List.unmodifiable(_phases);
  }

  void _recomputePhaseStatuses() {
    final sorted = [..._phases]..sort((a, b) => a.order.compareTo(b.order));
    var previousCompleted = true;
    final updated = <OjtRequirementPhase>[];

    for (final phase in sorted) {
      final fulfilled = phase.isFulfilled;
      final PhaseStatus status;
      if (!previousCompleted) {
        status = PhaseStatus.locked;
      } else if (fulfilled) {
        status = PhaseStatus.completed;
      } else {
        status = PhaseStatus.inProgress;
      }
      updated.add(phase.copyWith(status: status));
      previousCompleted = fulfilled;
    }

    _phases = updated;
  }
}

List<OjtRequirementPhase> _buildInitialPhases() {
  return [
    const OjtRequirementPhase(
      id: 'phase-1',
      order: 1,
      title: 'Pre-Application',
      description: 'Submit your Pre-Application Form & Company Details.',
      status: PhaseStatus.inProgress,
      documents: [
        OjtRequirementDoc(
          id: 'pre-app-form',
          name: 'Pre-Application Form',
          description: 'Basic student and company information form.',
          status: RequirementDocStatus.missing,
          hasTemplate: true,
        ),
        OjtRequirementDoc(
          id: 'company-details',
          name: 'Company Details',
          description: 'Details of your chosen HTE.',
          status: RequirementDocStatus.missing,
        ),
      ],
    ),
    const OjtRequirementPhase(
      id: 'phase-2',
      order: 2,
      title: 'Requirements',
      description: 'Submit Required Documents to proceed.',
      status: PhaseStatus.locked,
      documents: [
        OjtRequirementDoc(
          id: 'resume',
          name: 'Resume',
          description: 'Updated resume/CV.',
          status: RequirementDocStatus.missing,
          hasTemplate: true,
        ),
        OjtRequirementDoc(
          id: 'application-letter',
          name: 'Application Letter',
          description: 'Letter of intent to the HTE.',
          status: RequirementDocStatus.missing,
          hasTemplate: true,
        ),
        OjtRequirementDoc(
          id: 'endorsement-letter',
          name: 'Endorsement Letter',
          description: 'Endorsement from the department.',
          status: RequirementDocStatus.missing,
        ),
        OjtRequirementDoc(
          id: 'moa',
          name: 'MOA',
          description: 'Memorandum of Agreement between school and HTE.',
          status: RequirementDocStatus.missing,
          hasTemplate: true,
        ),
        OjtRequirementDoc(
          id: 'parent-consent',
          name: 'Parent Consent',
          description: 'Signed parental consent form.',
          status: RequirementDocStatus.missing,
          hasTemplate: true,
        ),
        OjtRequirementDoc(
          id: 'medical-certificate',
          name: 'Medical Certificate',
          description: 'Certificate of fitness to work.',
          status: RequirementDocStatus.missing,
        ),
        OjtRequirementDoc(
          id: 'insurance',
          name: 'Insurance',
          description: 'Proof of student insurance coverage.',
          status: RequirementDocStatus.missing,
        ),
      ],
    ),
    const OjtRequirementPhase(
      id: 'phase-3',
      order: 3,
      title: 'Internship Docs',
      description: 'Submit Internship Related Documents.',
      status: PhaseStatus.locked,
      documents: [
        OjtRequirementDoc(
          id: 'weekly-report',
          name: 'Weekly Report',
          description: 'Weekly activity report.',
          status: RequirementDocStatus.missing,
          hasTemplate: true,
        ),
        OjtRequirementDoc(
          id: 'monthly-report',
          name: 'Monthly Report',
          description: 'Monthly summary report.',
          status: RequirementDocStatus.missing,
          hasTemplate: true,
        ),
        OjtRequirementDoc(
          id: 'attendance',
          name: 'Attendance',
          description: 'Attendance summary for the period.',
          status: RequirementDocStatus.missing,
        ),
        OjtRequirementDoc(
          id: 'supervisor-evaluation',
          name: 'Supervisor Evaluation',
          description: 'Evaluation from your HTE supervisor.',
          status: RequirementDocStatus.missing,
        ),
        OjtRequirementDoc(
          id: 'faculty-evaluation',
          name: 'Faculty Evaluation',
          description: 'Evaluation from your assigned instructor.',
          status: RequirementDocStatus.missing,
        ),
        OjtRequirementDoc(
          id: 'company-evaluation',
          name: 'Company Evaluation',
          description: 'Evaluation of the HTE by the student.',
          status: RequirementDocStatus.missing,
        ),
      ],
    ),
    const OjtRequirementPhase(
      id: 'phase-4',
      order: 4,
      title: 'Final Documents',
      description: 'Track the Status & Submission of All Documents.',
      status: PhaseStatus.locked,
      documents: [
        OjtRequirementDoc(
          id: 'final-report',
          name: 'Final Report',
          description: 'Comprehensive final OJT report.',
          status: RequirementDocStatus.missing,
          hasTemplate: true,
        ),
        OjtRequirementDoc(
          id: 'completion-certificate',
          name: 'Completion Certificate',
          description: 'Certificate of completion from the HTE.',
          status: RequirementDocStatus.missing,
        ),
        OjtRequirementDoc(
          id: 'clearance',
          name: 'Clearance',
          description: 'Department clearance form.',
          status: RequirementDocStatus.missing,
          hasTemplate: true,
        ),
        OjtRequirementDoc(
          id: 'exit-evaluation',
          name: 'Exit Evaluation',
          description: 'Final exit evaluation form.',
          status: RequirementDocStatus.missing,
        ),
        OjtRequirementDoc(
          id: 'final-rating',
          name: 'Final Rating',
          description: 'Final rating given by the HTE.',
          status: RequirementDocStatus.missing,
        ),
      ],
    ),
  ];
}
