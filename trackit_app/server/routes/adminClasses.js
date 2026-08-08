const express = require('express');
const pool = require('../db');
const { requireAdminAuth } = require('../middleware/adminAuth');
const { generateUniqueCode } = require('../utils/activationCode');
const { toCsv } = require('../utils/csv');

const router = express.Router();
router.use(requireAdminAuth);

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

async function loadClassStudents(classId) {
  const result = await pool.query(
    `SELECT s.id, s.name, s.student_number, s.avatar_url,
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
    studentNumber: row.student_number,
    avatarUrl: row.avatar_url,
    assignedCompany: row.company_name,
    status: computeStudentStatus(row.company_name, row.last_login),
    contactPerson: row.emergency_contact,
    ojtSupervisor: row.company_supervisor_name,
  }));
}

// All classes school-wide -- unlike the instructor's own GET
// /api/teacher/classes, this isn't scoped to one instructor_id, since an
// admin oversees every section.
router.get('/', async (req, res) => {
  try {
    const { search } = req.query;
    const params = [];
    let where = '';
    if (search) {
      params.push(`%${search.toString().toLowerCase()}%`);
      where = `WHERE LOWER(c.program) LIKE $1 OR LOWER(c.section) LIKE $1 OR LOWER(a.name) LIKE $1`;
    }

    const result = await pool.query(
      `SELECT c.*, a.name AS instructor_name, COUNT(sp.student_id) AS student_count
       FROM instructor_classes c
       JOIN advisers a ON a.id = c.instructor_id
       LEFT JOIN student_profiles sp ON sp.class_id = c.id
       ${where}
       GROUP BY c.id, a.name
       ORDER BY c.program ASC, c.section ASC`,
      params,
    );
    res.json({
      success: true,
      classes: result.rows.map((row) => ({
        id: Number(row.id),
        program: row.program,
        section: row.section,
        academicYear: row.academic_year,
        instructorName: row.instructor_name,
        studentCount: Number(row.student_count),
      })),
    });
  } catch (error) {
    console.error('Get admin classes error:', error);
    res.status(500).json({ success: false, message: 'Failed to load classes.' });
  }
});

// Registered before the "/:id" route below -- Express matches routes in
// registration order, and "/:id" would otherwise swallow "/export" as if
// "export" were an id (Number('export') => NaN, silently breaking this
// endpoint).
const EXPORT_COLUMNS = [
  { key: 'program', label: 'Program' },
  { key: 'section', label: 'Section' },
  { key: 'academicYear', label: 'Academic Year' },
  { key: 'instructorName', label: 'Instructor' },
  { key: 'studentName', label: 'Student Name' },
  { key: 'studentNumber', label: 'Student Number' },
  { key: 'assignedCompany', label: 'Assigned Company' },
  { key: 'status', label: 'Status' },
  { key: 'contactPerson', label: 'Contact Person' },
  { key: 'ojtSupervisor', label: 'OJT Supervisor' },
];

// One export endpoint covers both "export one section" and "export
// multiple sections together" -- ids is always a list, just length 1
// for the single-section case.
router.get('/export', async (req, res) => {
  try {
    const idsParam = (req.query.ids || '').toString();
    const ids = idsParam
      .split(',')
      .map((s) => Number(s.trim()))
      .filter((n) => Number.isInteger(n) && n > 0);
    if (ids.length === 0) {
      return res.status(400).json({ success: false, message: 'ids is required.' });
    }

    const classesResult = await pool.query(
      `SELECT c.*, a.name AS instructor_name
       FROM instructor_classes c
       JOIN advisers a ON a.id = c.instructor_id
       WHERE c.id = ANY($1::bigint[])`,
      [ids],
    );

    const rows = [];
    for (const classRow of classesResult.rows) {
      const students = await loadClassStudents(classRow.id);
      for (const student of students) {
        rows.push({
          program: classRow.program,
          section: classRow.section,
          academicYear: classRow.academic_year,
          instructorName: classRow.instructor_name,
          studentName: student.name,
          studentNumber: student.studentNumber,
          assignedCompany: student.assignedCompany || 'N/A',
          status: student.status,
          contactPerson: student.contactPerson || '',
          ojtSupervisor: student.ojtSupervisor || '',
        });
      }
    }

    const csv = toCsv(EXPORT_COLUMNS, rows);
    // Strip characters that would break the quoted Content-Disposition
    // filename (program/section are instructor-entered, not fully trusted).
    const sanitize = (s) => s.replace(/["\r\n]/g, '').trim();
    const filename =
      classesResult.rows.length === 1
        ? `${sanitize(classesResult.rows[0].program)}-${sanitize(classesResult.rows[0].section)}.csv`
        : `trackit-export-${ids.length}-sections.csv`;

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.send(csv);
  } catch (error) {
    console.error('Export classes error:', error);
    res.status(500).json({ success: false, message: 'Failed to export data.' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const classId = Number(req.params.id);
    const result = await pool.query(
      `SELECT c.*, a.name AS instructor_name, a.email AS instructor_email
       FROM instructor_classes c
       JOIN advisers a ON a.id = c.instructor_id
       WHERE c.id = $1`,
      [classId],
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Class not found.' });
    }
    const row = result.rows[0];
    const students = await loadClassStudents(classId);

    // Year level isn't stored on the class itself (students have their
    // own year_level) -- report it only when every enrolled student
    // agrees, rather than guessing at a single "class year level" that
    // might not be true for everyone in a mixed section.
    const yearLevelResult = await pool.query(
      `SELECT DISTINCT s.year_level FROM students s
       JOIN student_profiles sp ON sp.student_id = s.id
       WHERE sp.class_id = $1 AND s.year_level IS NOT NULL`,
      [classId],
    );
    const yearLevel =
      yearLevelResult.rows.length === 1 ? yearLevelResult.rows[0].year_level : null;

    res.json({
      success: true,
      class: {
        id: Number(row.id),
        program: row.program,
        programFullName: programFullName(row.program),
        section: row.section,
        academicYear: row.academic_year,
        yearLevel,
        instructorName: row.instructor_name,
        instructorEmail: row.instructor_email,
        activationCode: row.activation_code,
        totalStudents: students.length,
        students,
      },
    });
  } catch (error) {
    console.error('Get admin class detail error:', error);
    res.status(500).json({ success: false, message: 'Failed to load class.' });
  }
});

// Admin generates/regenerates the code -- per the spec, this replaces
// the instructor's own class-creation code generation as the real
// source of activation codes going forward.
router.patch('/:id/regenerate-code', async (req, res) => {
  try {
    const classId = Number(req.params.id);
    const code = await generateUniqueCode();
    const result = await pool.query(
      `UPDATE instructor_classes SET activation_code = $1 WHERE id = $2 RETURNING activation_code`,
      [code, classId],
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Class not found.' });
    }
    res.json({ success: true, activationCode: result.rows[0].activation_code });
  } catch (error) {
    console.error('Regenerate activation code error:', error);
    res.status(500).json({ success: false, message: 'Failed to regenerate code.' });
  }
});

module.exports = router;
