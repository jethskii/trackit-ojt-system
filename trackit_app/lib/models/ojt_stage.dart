/// Where a student is in the OJT lifecycle -- distinct from
/// [OjtProgressStatus] (which tracks pace, not stage). No tile/filter
/// label for [notStarted] on the dashboard, but it's a valid bucket
/// (still working through Requirements / hasn't confirmed a company).
enum OjtStage { notStarted, readyForDeployment, active, completed }

OjtStage ojtStageFromDb(String value) {
  switch (value) {
    case 'readyForDeployment':
      return OjtStage.readyForDeployment;
    case 'active':
      return OjtStage.active;
    case 'completed':
      return OjtStage.completed;
    default:
      return OjtStage.notStarted;
  }
}
