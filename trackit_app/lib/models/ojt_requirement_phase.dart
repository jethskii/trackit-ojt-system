import 'ojt_requirement_doc.dart';

enum PhaseStatus { locked, inProgress, completed }

class OjtRequirementPhase {
  final String id;
  final int order;
  final String title;
  final String description;
  final PhaseStatus status;
  final List<OjtRequirementDoc> documents;

  const OjtRequirementPhase({
    required this.id,
    required this.order,
    required this.title,
    required this.description,
    required this.status,
    required this.documents,
  });

  bool get isFulfilled => documents.every(
    (d) =>
        d.status == RequirementDocStatus.submitted ||
        d.status == RequirementDocStatus.approved,
  );

  OjtRequirementPhase copyWith({
    PhaseStatus? status,
    List<OjtRequirementDoc>? documents,
  }) {
    return OjtRequirementPhase(
      id: id,
      order: order,
      title: title,
      description: description,
      status: status ?? this.status,
      documents: documents ?? this.documents,
    );
  }
}
