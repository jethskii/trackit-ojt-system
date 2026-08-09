// Shared by adminClasses.js (live) and adminArchive.js (read-only past
// years) so both compute program names and student status the exact same
// way -- an archived year should look like a real historical snapshot of
// the same live logic, not a separately-drifting copy of it.

const INACTIVE_AFTER_MS = 30 * 24 * 60 * 60 * 1000; // 30 days

// A small static reference lookup, not per-record data -- there's no
// "programs" table in this schema, just a short code on each class/
// student (e.g. "BSIT"). Falls back to the raw code for anything not
// listed rather than guessing.
const PROGRAM_NAMES = {
  BSIT: 'Bachelor of Science in Information Technology',
  BSCS: 'Bachelor of Science in Computer Science',
  BSIS: 'Bachelor of Science in Information Systems',
  BSCPE: 'Bachelor of Science in Computer Engineering',
};

function programFullName(code) {
  if (!code) return null;
  return PROGRAM_NAMES[code.toUpperCase().replace(/\s+/g, '')] || code;
}

// Real signal, not fabricated: "Assigned" once the student has
// self-reported a company (Confirm Company Details), "Inactive" if
// they haven't logged in within 30 days (real login_history data),
// otherwise "Preparing".
function computeStudentStatus(companyName, lastLoginAt) {
  if (companyName) return 'assigned';
  if (lastLoginAt && Date.now() - new Date(lastLoginAt).getTime() < INACTIVE_AFTER_MS) {
    return 'preparing';
  }
  return 'inactive';
}

module.exports = { programFullName, computeStudentStatus };
