const MS_PER_DAY = 24 * 60 * 60 * 1000;

// One slot per OJT week, from ojtStartDate through the current week --
// shared by the student's own Activity Reports endpoint and the
// instructor's read-only Weekly AR compilation view, so both list the
// exact same set of weeks for a given student.
function generateWeeks(ojtStartDate) {
  const start = new Date(ojtStartDate);
  const now = new Date();
  const daysElapsed = Math.max(0, Math.floor((now - start) / MS_PER_DAY));
  const currentWeek = Math.floor(daysElapsed / 7) + 1;

  const weeks = [];
  for (let n = 1; n <= currentWeek; n++) {
    const weekStart = new Date(start.getTime() + (n - 1) * 7 * MS_PER_DAY);
    const weekEnd = new Date(weekStart.getTime() + 6 * MS_PER_DAY);
    weeks.push({ weekNumber: n, weekStartDate: weekStart, weekEndDate: weekEnd });
  }
  return weeks;
}

module.exports = { generateWeeks };
