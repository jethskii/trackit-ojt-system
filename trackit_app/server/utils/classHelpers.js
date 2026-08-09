// Shared by adminClasses.js (live) and adminArchive.js (read-only past
// years) so both compute program names and student status the exact same
// way -- an archived year should look like a real historical snapshot of
// the same live logic, not a separately-drifting copy of it.

const pool = require('../db');

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

// There's no explicit "close out the year" action anywhere in this app,
// so "current" is inferred: the most recent academic_year string found
// among real classes. Everything else is, by definition, a past year.
// Academic years are always stored as "YYYY-YYYY", same length, so plain
// string DESC sorting is a correct year sort too.
async function getCurrentAcademicYear() {
  const result = await pool.query(
    'SELECT academic_year FROM instructor_classes ORDER BY academic_year DESC LIMIT 1',
  );
  return result.rows[0]?.academic_year ?? null;
}

// Shared by adminClasses.js and adminInstructors.js -- the Instructor
// Overview's "Enrolled Students" list needs the exact same student rows
// (with the same account-activation fields) as the Sections/Students
// overview, since both are views into the same underlying
// Instructor -> Section -> Students relationship.
async function loadClassStudents(classId) {
  const result = await pool.query(
    `SELECT s.id, s.name, s.email, s.student_number, s.avatar_url, s.activated_at,
            sp.company_name, sp.company_supervisor_name, sp.emergency_contact,
            lh.last_login
     FROM students s
     JOIN student_profiles sp ON sp.student_id = s.id
     LEFT JOIN LATERAL (
       SELECT MAX(login_at) AS last_login FROM login_history WHERE student_id = s.id
     ) lh ON true
     WHERE sp.class_id = $1
     ORDER BY s.name ASC`,
    [classId],
  );
  return result.rows.map((row) => ({
    id: Number(row.id),
    name: row.name,
    email: row.email,
    studentNumber: row.student_number,
    avatarUrl: row.avatar_url,
    assignedCompany: row.company_name,
    status: computeStudentStatus(row.company_name, row.last_login),
    contactPerson: row.emergency_contact,
    ojtSupervisor: row.company_supervisor_name,
    // Account activation -- separate from the OJT-progress `status`
    // above. Imported students start with no password (Pending) until
    // they register themselves with the section's activation code.
    accountStatus: row.activated_at ? 'activated' : 'pending',
    dateActivated: row.activated_at,
  }));
}

module.exports = {
  programFullName,
  computeStudentStatus,
  getCurrentAcademicYear,
  loadClassStudents,
};
