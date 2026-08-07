// Shared between routes/attendance.js (student's own Home/Attendance tabs)
// and routes/teacherStudents.js (Teacher module's Students tab) so the
// On Track/Behind/Needs Attention/Ahead of Schedule/Completed status
// means exactly the same thing everywhere it's shown.

// Assumed OJT work pace (standard Mon-Fri, 8hr/day) used to derive an
// "expected hours by now" baseline from ojt_start_date, since there's no
// separate target-hours-per-week field. Only used for the status badge.
const ASSUMED_HOURS_PER_WORKDAY = 8;

// On Track/Behind/Needs Attention/Ahead of Schedule/Completed, compared
// against the pace implied by ojt_start_date. Without a start date yet
// (company not confirmed), defaults to 'onTrack' since there's no
// baseline to fall behind on.
function computeProgressStatus({
  completedHours,
  requiredHours,
  ojtStartDate,
  lastAttendanceDate,
}) {
  if (completedHours >= requiredHours) return 'completed';
  if (!ojtStartDate) return 'onTrack';

  const msPerDay = 24 * 60 * 60 * 1000;
  const now = new Date();
  const start = new Date(ojtStartDate);
  const daysElapsed = Math.max(0, Math.floor((now - start) / msPerDay));

  const fullWeeksElapsed = Math.floor(daysElapsed / 7);
  const remainderDays = Math.min(5, daysElapsed % 7);
  const expectedWorkdays = fullWeeksElapsed * 5 + remainderDays;
  const expectedHours = Math.min(
    requiredHours,
    expectedWorkdays * ASSUMED_HOURS_PER_WORKDAY,
  );

  if (expectedHours <= 0) return 'onTrack';

  const paceRatio = completedHours / expectedHours;
  const daysSinceLastAttendance = lastAttendanceDate
    ? Math.floor((now - new Date(lastAttendanceDate)) / msPerDay)
    : daysElapsed;

  if (paceRatio < 0.7 || daysSinceLastAttendance >= 7) return 'needsAttention';
  if (paceRatio < 0.9) return 'behind';
  if (paceRatio > 1.1) return 'aheadOfSchedule';
  return 'onTrack';
}

// The lifecycle bucket shown on the Teacher dashboard/Students tab --
// distinct from the pace status above. 'notStarted' has no tile of its
// own (students still working through Requirements), but is a valid
// filter value. Called "Ready for Deployment" on the dashboard and
// "Preparing" on the Students tab -- same bucket, the wire value stays
// readyForDeployment either way.
function computeStage({ completedHours, requiredHours, hasStarted }) {
  if (completedHours >= requiredHours) return 'completed';
  if (hasStarted && completedHours > 0) return 'active';
  if (hasStarted) return 'readyForDeployment';
  return 'notStarted';
}

module.exports = { computeProgressStatus, computeStage };
