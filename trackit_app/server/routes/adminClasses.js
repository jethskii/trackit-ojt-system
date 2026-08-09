const express = require('express');
const multer = require('multer');
const pool = require('../db');
const { requireAdminAuth } = require('../middleware/adminAuth');
const { generateUniqueCode } = require('../utils/activationCode');
const { toCsv } = require('../utils/csv');
const { parseCsvRecords } = require('../utils/csvParse');
const {
  programFullName,
  computeStudentStatus,
  getCurrentAcademicYear,
} = require('../utils/classHelpers');

const router = express.Router();
router.use(requireAdminAuth);

// Import Students reads the CSV into memory and parses it directly --
// there's no reason to persist the uploaded file itself on disk.
const uploadCsv = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 2 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ['text/csv', 'application/vnd.ms-excel', 'application/csv'];
    const isCsvExt = file.originalname.toLowerCase().endsWith('.csv');
    cb(null, isCsvExt || allowed.includes(file.mimetype));
  },
});

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

// All classes school-wide -- unlike the instructor's own GET
// /api/teacher/classes, this isn't scoped to one instructor_id, since an
// admin oversees every section. instructor_id is nullable (Admin can
// create a section before Faculty assignment exists), so this is a LEFT
// JOIN -- an unassigned section must still show up, just with a null
// instructor name rather than being silently excluded.
router.get('/', async (req, res) => {
  try {
    const { search, academicYear } = req.query;
    const params = [];
    const conditions = [];
    if (academicYear) {
      params.push(academicYear.toString());
      conditions.push(`c.academic_year = $${params.length}`);
    }
    if (search) {
      params.push(`%${search.toString().toLowerCase()}%`);
      conditions.push(
        `(LOWER(c.program) LIKE $${params.length} OR LOWER(c.section) LIKE $${params.length} OR LOWER(a.name) LIKE $${params.length})`,
      );
    }
    const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const result = await pool.query(
      `SELECT c.*, a.name AS instructor_name, COUNT(sp.student_id) AS student_count
       FROM instructor_classes c
       LEFT JOIN advisers a ON a.id = c.instructor_id
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

// Every distinct academic year with real classes, plus the computed
// "current" one -- shown as "Active" in the picker. The dropdown may
// also offer a not-yet-used year (Create Section's target for the very
// first section of a new year); that one simply won't appear here until
// a class actually exists for it.
router.get('/academic-years', async (req, res) => {
  try {
    const currentYear = await getCurrentAcademicYear();
    const result = await pool.query(
      `SELECT academic_year, COUNT(*) AS class_count
       FROM instructor_classes
       GROUP BY academic_year
       ORDER BY academic_year DESC`,
    );
    res.json({
      success: true,
      academicYears: result.rows.map((row) => ({
        year: row.academic_year,
        classCount: Number(row.class_count),
        isCurrent: row.academic_year === currentYear,
      })),
    });
  } catch (error) {
    console.error('Get admin academic years error:', error);
    res.status(500).json({ success: false, message: 'Failed to load academic years.' });
  }
});

const ACADEMIC_YEAR_PATTERN = /^\d{4}-\d{4}$/;

// Admin creates a section with no instructor required yet (Faculty
// assignment is a separate, not-yet-built feature) -- generates its
// Student Activation Code immediately so it's usable the moment it's
// created.
router.post('/', async (req, res) => {
  try {
    const { program, section, academicYear } = req.body;
    if (!program || !program.toString().trim()) {
      return res.status(400).json({ success: false, message: 'Program is required.' });
    }
    if (!section || !section.toString().trim()) {
      return res.status(400).json({ success: false, message: 'Section is required.' });
    }
    if (!academicYear || !ACADEMIC_YEAR_PATTERN.test(academicYear.toString().trim())) {
      return res.status(400).json({
        success: false,
        message: 'Academic year must be in the format YYYY-YYYY.',
      });
    }

    const programTrimmed = program.toString().trim();
    const sectionTrimmed = section.toString().trim();
    const academicYearTrimmed = academicYear.toString().trim();

    const existing = await pool.query(
      `SELECT id FROM instructor_classes
       WHERE LOWER(program) = LOWER($1) AND LOWER(section) = LOWER($2) AND academic_year = $3`,
      [programTrimmed, sectionTrimmed, academicYearTrimmed],
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'A section with this program, section, and academic year already exists.',
      });
    }

    const code = await generateUniqueCode();
    const inserted = await pool.query(
      `INSERT INTO instructor_classes (instructor_id, program, section, academic_year, activation_code)
       VALUES (NULL, $1, $2, $3, $4)
       RETURNING id, program, section, academic_year`,
      [programTrimmed, sectionTrimmed, academicYearTrimmed, code],
    );
    const row = inserted.rows[0];

    res.status(201).json({
      success: true,
      class: {
        id: Number(row.id),
        program: row.program,
        section: row.section,
        academicYear: row.academic_year,
        instructorName: null,
        studentCount: 0,
      },
    });
  } catch (error) {
    console.error('Create section error:', error);
    res.status(500).json({ success: false, message: 'Failed to create section.' });
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
       LEFT JOIN advisers a ON a.id = c.instructor_id
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
          instructorName: classRow.instructor_name || 'Unassigned',
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
       LEFT JOIN advisers a ON a.id = c.instructor_id
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
        activationCodeCreatedAt: row.activation_code_created_at,
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
      `UPDATE instructor_classes
       SET activation_code = $1, activation_code_created_at = now()
       WHERE id = $2
       RETURNING activation_code, activation_code_created_at`,
      [code, classId],
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Class not found.' });
    }
    res.json({
      success: true,
      activationCode: result.rows[0].activation_code,
      activationCodeCreatedAt: result.rows[0].activation_code_created_at,
    });
  } catch (error) {
    console.error('Regenerate activation code error:', error);
    res.status(500).json({ success: false, message: 'Failed to regenerate code.' });
  }
});

// Import Students -- a CSV of (at minimum) Full Name + Email, associated
// with this section + its academic year. Each row becomes a real,
// persisted student account with no password yet (Pending); the student
// activates it themselves later by registering with this section's
// activation code, which claims the row rather than creating a
// duplicate (see routes/auth.js).
router.post('/:id/import-students', uploadCsv.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No CSV file uploaded.' });
    }
    const classId = Number(req.params.id);
    const classResult = await pool.query(
      'SELECT id, program, section FROM instructor_classes WHERE id = $1',
      [classId],
    );
    if (classResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Section not found.' });
    }
    const targetClass = classResult.rows[0];

    let records;
    try {
      records = parseCsvRecords(req.file.buffer.toString('utf8'));
    } catch {
      return res.status(400).json({ success: false, message: 'Could not read that CSV file.' });
    }
    if (records.length === 0) {
      return res.status(400).json({ success: false, message: 'The CSV file has no rows to import.' });
    }

    let created = 0;
    const skipped = [];

    for (const record of records) {
      const name = (record['full name'] || record['name'] || '').trim();
      const email = (record['email'] || '').trim().toLowerCase();
      const studentNumber = (record['student number'] || record['student id'] || '').trim() || null;

      if (!name || !email) {
        skipped.push({ email: email || '(blank)', reason: 'Missing name or email.' });
        continue;
      }

      const existing = await pool.query('SELECT id FROM students WHERE email = $1', [email]);
      if (existing.rows.length > 0) {
        skipped.push({ email, reason: 'An account with this email already exists.' });
        continue;
      }

      const inserted = await pool.query(
        `INSERT INTO students (name, email, password_hash, course, section, student_number)
         VALUES ($1, $2, NULL, $3, $4, $5)
         RETURNING id`,
        [name, email, targetClass.program, targetClass.section, studentNumber],
      );
      const studentId = inserted.rows[0].id;

      await pool.query(
        `INSERT INTO student_profiles (student_id, class_id)
         VALUES ($1, $2)
         ON CONFLICT (student_id) DO UPDATE SET class_id = $2, updated_at = now()`,
        [studentId, classId],
      );
      created += 1;
    }

    res.json({ success: true, created, skipped });
  } catch (error) {
    console.error('Import students error:', error);
    res.status(500).json({ success: false, message: 'Failed to import students.' });
  }
});

module.exports = router;
