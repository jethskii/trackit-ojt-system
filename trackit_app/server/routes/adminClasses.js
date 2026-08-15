const express = require('express');
const multer = require('multer');
const PDFDocument = require('pdfkit');
const ExcelJS = require('exceljs');
const pool = require('../db');
const { requireAdminAuth } = require('../middleware/adminAuth');
const { generateUniqueCode } = require('../utils/activationCode');
const { toCsv } = require('../utils/csv');
const { parseCsvRecords } = require('../utils/csvParse');
const { parseXlsxRecords } = require('../utils/xlsxParse');
const {
  programFullName,
  getCurrentAcademicYear,
  loadClassStudents,
} = require('../utils/classHelpers');

const router = express.Router();
router.use(requireAdminAuth);

// Import Students reads the file into memory and parses it directly --
// there's no reason to persist the uploaded file itself on disk. Accepts
// both CSV and the downloadable .xlsx template (see /import-template).
const uploadImport = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedMime = [
      'text/csv',
      'application/vnd.ms-excel',
      'application/csv',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ];
    const name = file.originalname.toLowerCase();
    const isAllowedExt = name.endsWith('.csv') || name.endsWith('.xlsx');
    cb(null, isAllowedExt || allowedMime.includes(file.mimetype));
  },
});

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

// A blank, downloadable starting point for Import Students -- headers
// match what the importer below actually recognizes. Registered before
// "/:id" for the same reason "/export" is: Express would otherwise try
// to match "import-template" as an :id.
router.get('/import-template', async (req, res) => {
  try {
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Students');
    sheet.columns = [
      { header: 'Last Name', key: 'lastName', width: 20 },
      { header: 'First Name', key: 'firstName', width: 20 },
      { header: 'Middle Initial', key: 'middleInitial', width: 16 },
      { header: 'Email', key: 'email', width: 30 },
      { header: 'Student Number', key: 'studentNumber', width: 18 },
      { header: 'Year', key: 'year', width: 14 },
    ];
    sheet.getRow(1).font = { bold: true };
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="trackit-student-import-template.xlsx"',
    );
    await workbook.xlsx.write(res);
    res.end();
  } catch (error) {
    console.error('Get import template error:', error);
    res.status(500).json({ success: false, message: 'Failed to build the import template.' });
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

// Fixed, non-customizable table -- same columns regardless of format,
// matching every row Class Management can already show per student.
function renderClassesPdf(doc, rows) {
  const columns = [
    { key: 'program', label: 'Program', width: 40 },
    { key: 'section', label: 'Section', width: 40 },
    { key: 'academicYear', label: 'A.Y.', width: 55 },
    { key: 'instructorName', label: 'Instructor', width: 80 },
    { key: 'studentName', label: 'Student Name', width: 100 },
    { key: 'studentNumber', label: 'Student No.', width: 65 },
    { key: 'assignedCompany', label: 'Company', width: 100 },
    { key: 'status', label: 'Status', width: 50 },
    { key: 'contactPerson', label: 'Contact Person', width: 90 },
    { key: 'ojtSupervisor', label: 'OJT Supervisor', width: 90 },
  ];
  const left = doc.page.margins.left;
  const rowHeight = 18;
  const tableWidth = columns.reduce((sum, c) => sum + c.width, 0);

  function drawHeaderRow(y) {
    doc.font('Helvetica-Bold').fontSize(8);
    let x = left;
    for (const col of columns) {
      doc.text(col.label, x, y, { width: col.width, ellipsis: true });
      x += col.width;
    }
    doc.moveTo(left, y + 13).lineTo(left + tableWidth, y + 13).strokeColor('#cccccc').stroke();
    doc.font('Helvetica').fontSize(7.5).fillColor('#000000');
  }

  doc.font('Helvetica-Bold').fontSize(16).text('TRACKIT Class Management Export');
  doc.moveDown(0.5);

  let y = doc.y + 4;
  drawHeaderRow(y);
  y += rowHeight;

  for (const row of rows) {
    if (y > doc.page.height - doc.page.margins.bottom - rowHeight) {
      doc.addPage();
      y = doc.page.margins.top;
      drawHeaderRow(y);
      y += rowHeight;
    }
    let x = left;
    for (const col of columns) {
      const value = row[col.key];
      doc.text(value === null || value === undefined ? '' : value.toString(), x, y, {
        width: col.width,
        ellipsis: true,
      });
      x += col.width;
    }
    y += rowHeight;
  }
}

// One export endpoint covers both "export one section" and "export
// multiple sections together" -- ids is always a list, just length 1
// for the single-section case -- in CSV, Excel, or PDF (?format=).
router.get('/export', async (req, res) => {
  try {
    const idsParam = (req.query.ids || '').toString();
    const format = (req.query.format || 'csv').toString().toLowerCase();
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
          studentNumber: student.studentNumber || '',
          assignedCompany: student.assignedCompany || 'N/A',
          status: student.status,
          contactPerson: student.contactPerson || '',
          ojtSupervisor: student.ojtSupervisor || '',
        });
      }
    }

    // Strip characters that would break the quoted Content-Disposition
    // filename (program/section are instructor-entered, not fully trusted).
    const sanitize = (s) => s.replace(/["\r\n]/g, '').trim();
    const baseFilename =
      classesResult.rows.length === 1
        ? `${sanitize(classesResult.rows[0].program)}-${sanitize(classesResult.rows[0].section)}`
        : `trackit-class-management-${ids.length}-sections`;

    if (format === 'xlsx') {
      const workbook = new ExcelJS.Workbook();
      const sheet = workbook.addWorksheet('Students');
      sheet.columns = EXPORT_COLUMNS.map((c) => ({ header: c.label, key: c.key, width: 20 }));
      sheet.addRows(rows);
      sheet.getRow(1).font = { bold: true };
      res.setHeader(
        'Content-Type',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      res.setHeader('Content-Disposition', `attachment; filename="${baseFilename}.xlsx"`);
      await workbook.xlsx.write(res);
      res.end();
      return;
    }

    if (format === 'pdf') {
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="${baseFilename}.pdf"`);
      const doc = new PDFDocument({ margin: 36, size: 'A4', layout: 'landscape' });
      doc.pipe(res);
      renderClassesPdf(doc, rows);
      doc.end();
      return;
    }

    const csv = toCsv(EXPORT_COLUMNS, rows);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${baseFilename}.csv"`);
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

// The Student Details panel's real data source -- reuses loadClassStudents
// (the exact same rows the student table itself renders, so the panel can
// never show a different status/company/contact than the row the admin
// clicked) and adds only what that shared helper doesn't already carry:
// contact info, company specifics, and hours/attendance for the progress
// section. Nested under the class so a student can only be looked up
// within a section the admin is actually viewing.
router.get('/:id/students/:studentId', async (req, res) => {
  try {
    const classId = Number(req.params.id);
    const studentId = Number(req.params.studentId);

    const classStudents = await loadClassStudents(classId);
    const base = classStudents.find((s) => s.id === studentId);
    if (!base) {
      return res
        .status(404)
        .json({ success: false, message: 'Student not found in this section.' });
    }

    const detailResult = await pool.query(
      `SELECT s.email, s.student_number, s.required_hours,
              sp.phone, sp.address, sp.company_address, sp.company_industry,
              sp.company_contact_number, sp.ojt_start_date,
              c.program, c.section
       FROM students s
       JOIN student_profiles sp ON sp.student_id = s.id
       JOIN instructor_classes c ON c.id = sp.class_id
       WHERE s.id = $1 AND sp.class_id = $2`,
      [studentId, classId],
    );
    if (detailResult.rows.length === 0) {
      return res
        .status(404)
        .json({ success: false, message: 'Student not found in this section.' });
    }
    const detail = detailResult.rows[0];

    const [hoursResult, weeklyResult] = await Promise.all([
      pool.query(
        `SELECT
           COUNT(*) FILTER (WHERE clock_out IS NOT NULL) AS days_attended,
           COALESCE(SUM(EXTRACT(EPOCH FROM (clock_out - clock_in)) / 3600.0)
             FILTER (WHERE clock_out IS NOT NULL), 0) AS completed_hours
         FROM attendance_records WHERE student_id = $1`,
        [studentId],
      ),
      pool.query(
        `SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (clock_out - clock_in)) / 3600.0), 0) AS weekly_hours
         FROM attendance_records
         WHERE student_id = $1 AND clock_out IS NOT NULL
           AND work_date >= (CURRENT_DATE - INTERVAL '7 days')`,
        [studentId],
      ),
    ]);

    res.json({
      success: true,
      student: {
        id: base.id,
        name: base.name,
        avatarUrl: base.avatarUrl,
        studentNumber: detail.student_number,
        accountStatus: base.accountStatus,
        dateActivated: base.dateActivated,
        ojtStatus: base.status,
        program: detail.program,
        section: detail.section,
        phone: detail.phone,
        email: detail.email,
        address: detail.address,
        guardianContact: base.contactPerson,
        company: base.assignedCompany
          ? {
              name: base.assignedCompany,
              industry: detail.company_industry,
              address: detail.company_address,
              dateDeployed: detail.ojt_start_date,
              supervisorName: base.ojtSupervisor,
              supervisorContact: detail.company_contact_number,
            }
          : null,
        progress: {
          completedHours: Number(hoursResult.rows[0].completed_hours),
          requiredHours: Number(detail.required_hours),
          daysAttended: Number(hoursResult.rows[0].days_attended),
          weeklyAverageHours: Number(weeklyResult.rows[0].weekly_hours),
        },
      },
    });
  } catch (error) {
    console.error('Get admin student detail error:', error);
    res.status(500).json({ success: false, message: 'Failed to load student.' });
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

// Import Students -- a CSV or .xlsx (see /import-template) of (at
// minimum) a name + email, associated with this section + its academic
// year. Each row becomes a real, persisted student account with no
// password yet (Pending); the student activates it themselves later by
// registering with this section's activation code, which claims the row
// rather than creating a duplicate (see routes/auth.js). Program/Section
// aren't read from the file -- they're implied by which section you're
// importing into.
router.post('/:id/import-students', uploadImport.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No file uploaded.' });
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

    const isXlsx = req.file.originalname.toLowerCase().endsWith('.xlsx');
    let records;
    try {
      records = isXlsx
        ? await parseXlsxRecords(req.file.buffer)
        : parseCsvRecords(req.file.buffer.toString('utf8'));
    } catch {
      return res.status(400).json({ success: false, message: 'Could not read that file.' });
    }
    if (records.length === 0) {
      return res.status(400).json({ success: false, message: 'The file has no rows to import.' });
    }

    let created = 0;
    const skipped = [];

    for (const record of records) {
      const lastName = (record['last name'] || '').trim();
      const firstName = (record['first name'] || '').trim();
      const middleInitial = (record['middle initial'] || record['m.i.'] || record['mi'] || '').trim();
      const splitNameParts = [firstName, middleInitial ? `${middleInitial}.` : '', lastName].filter(
        (part) => part.length > 0,
      );
      const name = (record['full name'] || record['name'] || '').trim() || splitNameParts.join(' ');
      const email = (record['email'] || '').trim().toLowerCase();
      const studentNumber = (record['student number'] || record['student id'] || '').trim() || null;
      const yearLevel = (record['year'] || record['year level'] || '').trim() || null;

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
        `INSERT INTO students (name, email, password_hash, course, section, student_number, year_level)
         VALUES ($1, $2, NULL, $3, $4, $5, $6)
         RETURNING id`,
        [name, email, targetClass.program, targetClass.section, studentNumber, yearLevel],
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
